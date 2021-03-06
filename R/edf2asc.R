##' @title Call SRR "edf2asc" command line utility to do some work.
##'
##' @description A convenience wrapper around the SR Research edf2asc file conversion utility.
##'
##' @details Call SR Research "edf2asc" command line utility to convert *edf files to *asc
##'     files. Each *asc file is placed in the same directory as the *edf file that it is derived
##'     from. Existing *asc files will NOT be over-written by default, because that is the default
##'     for the SRR edf2asc utility.
##'
##'     This function expects to find the fully qualified path to the edf2asc executable via
##'     getOption("FDBeye_edf2asc_exec"). The user can set the option by calling
##'     option(FDBeye_edf2asc_exec = "/path/to/edf2asc.exe"). If done in the script itself, the
##'     setting will be in effect for the duration of the R session. If done in the user's .Rprofile
##'     file, the setting will persist across R sessions.
##'
##'     Before calling the utility, this function will check to see that the specified file exists
##'     and is executable. As a meager security check, we also ensure that the basename of the file
##'     includes the string "edf2asc". However, if the selected version of the edf2asc executable is
##'     in some way incompatible with your platform, then this function will fail with a cryptic
##'     error. The best way to guard against this is to check that your edf2asc executable file
##'     works as expected from the command line before attempting to use it from within FDBeye.
##'
##'     The function edf2asc() also checks getOption("FDBeye_edf2asc_opts"). If this option
##'     exists, it should be a valid string of command line options to pass to the SRR edf2asc
##'     utility (e.g., "-y -ns"). See the SRR documentation for details.
##'
##'     In addition to creating the requested *asc files, this function will write a log file
##'     ('edf2asc.log') of messages captured from the stdout of SRR edf2asc utility and place it in
##'     the current working directory.
##'
##'     \enumerate{
##'          \item The best way to get the edf2asc utility is to install the Eyelink Developers Kit:
##'             https://www.sr-support.com/showthread.php?6-EyeLink-Developers-Kit-for-Windows-%28Windows-Display-Software%29.
##'          \item Documentation is in the EL1000+ manual, section 4.8 "Using ASC files".
##'          \item Make sure edfapi library (e.g., edfapi.dll) is somewhere on the PATH.
##'     }
##'
##' @param edffiles Character vector of *edf file names to be converted. File names should include
##'     paths relative to the current working directory, or fully qualified paths.
##' @return Called for the side effect of converting SRR *edf files to *asc files. Returns a
##'     character vector listing output files (*asc files).
##' @author Dave Braze \email{davebraze@@gmail.com}
##' @export
##' @examples
##' \dontrun{
##' option(FDBeye_edf2asc_exec = "/path/to/edf2asc.exe") ## this only needs to  be done once.
##'
##' fin <- list.files(".", pattern="edf$", recursive=TRUE)
##' fout <- edf2asc(fin)
##' fout
##' }
edf2asc <- function(edffiles) {

    exe <- getOption("FDBeye_edf2asc_exec")
    opts <-  getOption("FDBeye_edf2asc_opts")
    if(is.null(opts)) {
        warning("FDBeye_edf2asc_opts not set. Using factory defaults.")
        opts <- ""
    }

    if(is.null(exe)){
        stop("You must set option(FDBeye_edf2asc_exec = '/path/to/edf2asc') before calling this function.")
    } else {
        ## First check to be sure the file actually exists and is executable
        if(!file_test("-f", exe))        # test whether file exists and is executable. Should I use base::file.exists() instead?
            stop(paste(exe, "... File either does not exist or is not executable.", sep="\n"))
        ## parse the specified path and make sure the fname includes "edf2asc"
        if(!grepl("edf2asc", basename(exe)))
            stop(paste(exe,
                       "... File does not appear to be an edf2asc executable file (based on its file name).",
                       sep="\n"))
    }

    for (ff in edffiles) {
        ## see R function shQuote() for help building the command line string.
        log <- system(paste(shQuote(exe), opts, shQuote(ff)),   ## should update this to use
                                                                ## system2() instead of system().
                      intern=TRUE)
        if(exists("logfile")) logfile <- c(logfile, log)
        else logfile <- log
    }

    ## should wrap this in a 'try' block.
    logfile <- logfile[-grep("^Processed", logfile)]
    h <- file("./edf2asc.log", "wb")
    cat(logfile, file=h, sep="\n")
    close(h)

    retval <- gsub("\\.edf$", ".asc", edffiles)
    retval
}
