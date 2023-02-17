# use conda? if not add mirror
if (!require(devtools)) install.packages("devtools", repos="http://cloud.r-project.org/")
if (!require(wilson)) devtools::install_github(repo = "loosolab/wilson", host="github.molgen.mpg.de/api/v3", auth_token = NULL, dependencies=FALSE)
if (!require(optparse)) install.packages("optparse", repos="http://cloud.r-project.org/"); library(optparse)

## utilize snakemake parameter
# Combine list with mandatory parameters with optional parameter list.
# As snakemake provides each element in snakemake@params twice (with/ without name), omit unnamed elements.
# args <- c(
# 	list(input = snakemake@input[[1]], output = snakemake@output[[1]]), 
# 	snakemake@params[which(names(snakemake@params) != "")]
# 	)
# do.call(what = wilson::tobias_parser, args = as.list(args))

## utilize command line arguments (called by RScript)
option_list <- list(
	make_option(opt_str = c("-i", "--input"), default = NULL, help = "Input bed-file.", metavar = "file"),
	make_option(opt_str = c("-o", "--output"), default = NULL, help = "Output file.", metavar = "file"),
	make_option(opt_str = c("-c", "--config"), default = NULL, help = "Config json file.", metavar = "file"),
	make_option(opt_str = c("-n", "--condition_names"), default = NULL, help = "File with one condition name per row. Used only for columns not defined by config.", metavar = "file")
)

opt_parser <- OptionParser(option_list = option_list)

opt <- parse_args(opt_parser)

# show help if called without arguments
if (length(commandArgs(trailingOnly = TRUE)) <= 0) {
	print_help(opt_parser)
} else {
	# remove last parameter (help param)
	params <- opt[-length(opt)]
	# read condition names and store in vector
	if (is.element("condition_names", names(params))) {
		params$condition_names <- scan(file = params$condition_names, what = character())
	}
	do.call(what = wilson::tobias_parser, args = params)
}
