#'@name defaultProcessInputs
#'@title Default Process Inputs
#'@param algorithm the WPS algorithm to get process inputs for
#'@param wps_url the service base URL for the WPS
#'@param wps_version the service version to use
#'@return list of default, optional, and required process inputs for use in the webprocess object.
#'@description parses DescribeProcess request
defaultProcessInputs <- function(algorithm, wps_url, wps_version){
  getCaps <- gGET(wps_url, query = list(
    'service' = 'WPS', 'version' = wps_version,'request' = 'DescribeProcess', 'identifier'=algorithm))

  
  doc = tryCatch({
    gcontent(getCaps)
  }, error = function(e) {
    warning(paste0(wps_url, ' does not seem to be a valid Web Processing Service url.'), 
            call. = FALSE)
    return(NULL)
  })

  checkException(doc)
  
  # -- get optional arguments --
  optionNd <- xml2::xml_find_all(doc,'//DataInputs/Input[@minOccurs=0]/ows:Identifier')
  optionLs <- vector("list",length(optionNd))
  optionLs[] <- NA # "NA" is the equivalent of "optional" as an input
  names(optionLs) <- xml2::xml_text(optionNd)
  
  # -- get required arguments -- (minOccurs > 0 means required)
  requirNd <- xml2::xml_find_all(doc,'//DataInputs/Input[@minOccurs>0]/ows:Identifier')
  requirLs <- vector("list",length(requirNd)) 
  names(requirLs) <- xml2::xml_text(requirNd)
  
  # -- get and set default values --
  defaultTag <- '//DataInputs/Input/LiteralData/DefaultValue'
  defaultNd <- xml2::xml_find_all(doc,paste0(defaultTag, '/parent::node()[1]/DefaultValue'))
  defaultLs <- vector("list",length(xml2::xml_text(defaultNd)))
  defaultLs[] <- xml2::xml_text(defaultNd)
  names(defaultLs) <- xml2::xml_text(xml2::xml_find_all(doc,
                                                        paste0(defaultTag, 
                                  '/parent::node()[1]/preceding-sibling::node()[3]'))) 
  
  
  # -- get and set allowed values -- ?? why isn't this set up like defaults??
  allowNd    <- xml2::xml_find_all(doc,
   '//DataInputs/Input/LiteralData//parent::node()/ows:AllowedValues/ows:Value[1]')
  allowLs <- vector("list",length(xml2::xml_text(allowNd)))
  allowLs[] <- xml2::xml_text(allowNd)
  names(allowLs) <- xml2::xml_text(
    xml2::xml_find_all(doc,
    '//DataInputs/Input/LiteralData/ows:AllowedValues/
    parent::node()[1]/preceding-sibling::node()[3]'))
  
  # add fields for optionLs and requirLs
  processInputs <- append(optionLs,requirLs)
  processInputs[names(defaultLs)] <- defaultLs
  
  # remove Feature, as it is handled elsewhere
  processInputs$FEATURE_COLLECTION <- NULL 
  return(processInputs)
}

checkException <- function(doc){
  exceptionTag <- '//ows:Exception/ows:ExceptionText'
  if(length(xml2::xml_find_all(doc, exceptionTag))>0){
    stop(xml2::xml_text(xml2::xml_find_all(doc, exceptionTag)[[1]]))
  }
}
