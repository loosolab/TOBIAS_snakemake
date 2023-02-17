"""
Upper level TOBIAS snake
"""

import os
import subprocess
import itertools
import glob
import datetime

snakemake.utils.min_version("5.4")	#for checkpoints functionality

#-------------------------------------------------------------------------------#
#---------------------- SETUP PROCESS-RELATED CONFIGURATION --------------------#
#-------------------------------------------------------------------------------#
try:
	CONFIGFILE = str(workflow.overwrite_configfiles[0])
except:
	CONFIGFILE = str(workflow.overwrite_configfile[0])

wd = os.getcwd()
config["wd"] = wd

#Get relative position of Snakefile from wd
SNAKEFILE = workflow.snakefile
SNAKEFILE_DIR = os.path.dirname(SNAKEFILE)
config["snakefile"] = SNAKEFILE
config["snakefile_dir"] = SNAKEFILE_DIR

#Establish snakefile and environment dictionaries
snakefiles_dir = os.path.abspath(os.path.join(SNAKEFILE_DIR, "snakefiles"))		#directory for additional snakefiles
environments_dir = os.path.abspath(os.path.join(SNAKEFILE_DIR, "environments"))	#directory for conda environment yaml files
scripts_dir = os.path.abspath(os.path.join(SNAKEFILE_DIR, "scripts")) 			#directory for extra scripts used in workflow

#Snake modules used to setup run
include: os.path.join(snakefiles_dir, "helper.snake")
shell.executable("/bin/bash")
#shell.prefix("source ~/.bashrc; ")

#Constrain wildcards to not jump into directories
wildcard_constraints:
	condition = "[a-zA-Z0-9\-_\.]+",
	TF = "[a-zA-Z0-9\-_\.]+",
	state = "bound|unbound",
	plotname = "[a-zA-Z0-9\-_\.]+",

#Save timestamp to config
config["timestamp"] = str(datetime.datetime.now())

#-------------------------------------------------------------------------------#
#------------------------- CHECK FORMAT OF CONFIG FILE -------------------------#
#-------------------------------------------------------------------------------#

required = [("data",),
			("run_info",),
				("run_info", "organism"),
				("run_info", "fasta"),
				("run_info", "blacklist"),
				("run_info", "gtf"),
				("run_info", "motifs"),
				("run_info", "output"),
			]

#Check if all keys are existing and contain information
for key_list in required:
	lookup_dict = config
	for key in key_list:
		try:
			lookup_dict = lookup_dict[key]
			if lookup_dict == None:
				print("ERROR: Missing input for key {0}".format(key_list))
		except:
			print("ERROR: Could not find key(s) \"{0}\" in configfile {1}. Please check that your configfile has right format for TOBIAS.".format(":".join(key_list), CONFIGFILE))
			sys.exit()

#Check if there is at least one condition with bamfiles
if len(config["data"]) > 0:
	for condition in config["data"]:
		if len(config["data"][condition]) == 0:
			print("ERROR: Could not find any bamfiles in \"{0}\" in configfile {1}".format(":".join(("data", condition)), CONFIGFILE))
else:
	print("ERROR: Could not find any conditions (\"data:\{condition\}\") in configfile {0}".format(CONFIGFILE))
	sys.exit()


#-------------------------------------------------------------------------------#
#------------------------------- HANDLE FLAGS ----------------------------------#
#-------------------------------------------------------------------------------#
# Decide which parts of pipeline to run (uses config["flags"])

all_flags = ["plot_comparison", 
  	     	 "plot_correction",
  		 	 "plot_venn",
		 	 "coverage",
			 "wilson"]

#Fill in values for flags
if "flags" not in config:
	config["flags"] = {}

#Check if given flags are valid
invalid_flags = set(config["flags"].keys()) - set(all_flags) 
if len(invalid_flags) > 0:
	print("ERROR: Flags '{0}' given in config are not valid. Valid flags are: {1}".format(invalid_flags, all_flags))
	sys.exit()

#Check format and fill in missing flags with default (True)
for flag in all_flags:
	if flag not in config["flags"]:
		config["flags"][flag] = True
	else:
		#Check if flag value is true/false
		if str(config["flags"][flag]).lower() in ["true", "t", "yes", "y"]:
			config["flags"][flag] = True
		elif str(config["flags"][flag]).lower() in ["false", "f", "no", "n"]:
			config["flags"][flag] = False
		else:
			print("ERROR: Value given for flag '{0}' is: '{1}'".format(flag, config["flags"][flag]))
			print("Value must be either 'True' or 'False'")
			sys.exit()

#-------------------------------------------------------------------------------#
#------------------------- WHICH FILES/INFO WERE INPUT? ------------------------#
#-------------------------------------------------------------------------------#

input_files = []

#Files related to experimental data (bam)
CONDITION_IDS = list(config["data"].keys())
for condition in CONDITION_IDS:
	if not isinstance(config["data"][condition], list):
		config['data'][condition] = [config['data'][condition]]

	cond_input = []
	for f in config['data'][condition]:
		globbed = glob.glob(f)
		if len(globbed) == 0:
			exit("ERROR: Could not find any files matching filename/pattern: {0}".format(f))
		else:
			cond_input.extend(globbed)

	config["data"][condition] = list(set(cond_input))						#remove duplicates
	input_files.extend(config['data'][condition])

#Flatfiles independent from experimental data
OUTPUTDIR = config['run_info']["output"]
FASTA = os.path.join(OUTPUTDIR, "flatfiles", os.path.basename(config['run_info']['fasta']))
BLACKLIST = os.path.join(OUTPUTDIR, "flatfiles", os.path.basename(config['run_info']['blacklist']))
GTF = os.path.join(OUTPUTDIR, "flatfiles", os.path.basename(config['run_info']['gtf']))

#Any additional files given to run_info
input_files.append(config["run_info"].get("peaks", None))
input_files.append(config["run_info"].get("peaks_header", None))

#---------- Test that input files exist -----------#

input_files.extend([config['run_info']['fasta'], config['run_info']['blacklist'], config['run_info']['gtf']])
for file in input_files:
	if file != None:
		if file == "":
			exit("ERROR: File given in config cannot be empty string (\"\")")

		full_path = os.path.abspath(file) 
		if not os.path.exists(full_path):
			exit("ERROR: The following file given in config does not exist: {0}".format(full_path))

#--------------------------------- MOTIFS ------------------------------#

#If not list, make it list and glob elements
if not isinstance(config['run_info']['motifs'], list):
	config['run_info']['motifs'] = [config['run_info']['motifs']]
motif_input = sum([glob.glob(element) for element in config['run_info']['motifs']], [])

#Test if input is directory or file
motif_files = []
for path in motif_input:

	#If input is dir; fetch all input files
	if os.path.isdir(path):
		files = os.listdir(path)
		motif_files.extend([os.path.join(path, f) for f in files])

	#If input is file, add to list of files
	elif os.path.isfile(path):
		motif_files.append(path)

motif_files = list(set(motif_files)) 	#remove duplicates
config['run_info']['motifs'] = sorted(motif_files)


#-------------------------------------------------------------------------------#
#------------------------ WHICH FILES SHOULD BE CREATED? -----------------------#
#-------------------------------------------------------------------------------#

output_files = []

id2bam = {condition:{} for condition in CONDITION_IDS}
for condition in CONDITION_IDS:
	config_bams = config['data'][condition]
	sampleids = [os.path.splitext(os.path.basename(bam))[0] for bam in config_bams]
	id2bam[condition] = {sampleids[i]:config_bams[i] for i in range(len(sampleids))}	# Link sample ids to bams

#Files always created
output_files.append(os.path.join(OUTPUTDIR, "config.yaml"))
output_files.append(expand(os.path.join(OUTPUTDIR, "footprinting", "{condition}_footprints.bw"), condition=CONDITION_IDS))
output_files.extend(expand(os.path.join(OUTPUTDIR, "overview", "all_{condition}_bound.bed"), condition=CONDITION_IDS)) #output from BINDetect
output_files.append(os.path.join(OUTPUTDIR, "overview", "TF_changes.pdf"))

#Wilson
if config["flags"]["wilson"] == True:
	#output_files.extend(expand(os.path.join(OUTPUTDIR, "wilson", "data", "{TF}_overview.clarion"), TF=TF_IDS))
	output_files.append(os.path.join(OUTPUTDIR, "wilson", "HOW_TO_WILSON.txt"))

#Visualization: decide what to plot (options depending on flags)
PLOTNAMES = []

if config["flags"]["plot_correction"] == True: #plot uncorrected/expected/corrected per condition
	PLOTNAMES.extend(expand("{condition}_{plotname}", condition=CONDITION_IDS, plotname=["aggregate"]))

if len(CONDITION_IDS) > 1:
	if config["flags"]["plot_comparison"] == True:
		PLOTNAMES.extend(["heatmap_comparison", "aggregate_comparison_all", "aggregate_comparison_bound"])

	if config["flags"]["plot_venn"] == True:
		if len(CONDITION_IDS) < 5:	#Only show venns for 4 conditions or less
			PLOTNAMES.append("venn_diagram")

output_files.extend(expand(os.path.join(OUTPUTDIR, "overview", "all_{plotname}.pdf"), plotname=PLOTNAMES))

#Additional optional output (decided by flags)
if config["flags"]["coverage"] == True:
	output_files.append(expand(os.path.join(OUTPUTDIR, "coverage", "{condition}_coverage.bw"), condition=CONDITION_IDS))

#Decide which peaks to use
if "peaks" in config["run_info"]: #triggers use of given peaks
	#Check for peaks_header
	if "peaks_header" not in config["run_info"]:
		config["run_info"]["peaks_header"] = os.path.join(OUTPUTDIR, "peak_annotation", "peaks_header.txt") #triggers create_peaks_header

else:
	config["run_info"]["peaks"] = os.path.join(OUTPUTDIR, "peak_annotation", "all_merged_annotated.bed") #will be created within run
	config["run_info"]["peaks_header"] = os.path.join(OUTPUTDIR, "peak_annotation", "all_merged_annotated_header.txt")


#TODO: Include RNA?

#-------------------------------------------------------------------------------#
#---------------------------------- RUN :-) ------------------------------------#
#-------------------------------------------------------------------------------#

include: os.path.join(snakefiles_dir, "preprocessing.snake")
include: os.path.join(snakefiles_dir, "footprinting.snake")
include: os.path.join(snakefiles_dir, "visualization.snake")
include: os.path.join(snakefiles_dir, "wilson.snake")

rule all:
	input: 
		output_files
	message: "Rule all"
