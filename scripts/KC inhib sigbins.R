KC.inhib.sigbins.Rfunc = function(path, startt, endt, event) {

load("C:/Users/Kevin Caref/Google Drive/RScripts/Functions/neuraldataextract.rFunc")
load("C:/Users/Kevin Caref/Google Drive/RScripts/Functions/eventfinder.rFunc")

#specify path of nex files
neuralpath = path
nexfiles = list.files(neuralpath)

#extracts all NeuroExplorer data
nexdata = lapply(nexfiles, function(x) {
  neuraldataextract.rFunc(paste(neuralpath, x, sep = ""))})
  
#for debugging purposes
#nexdata = list()
#for(i in (1:length(nexfiles))) (
#   nexdata[[i]] = neuraldataextract.rFunc(paste(neuralpath, nexfiles[i], sep = ""))) 

load("C:/Users/Kevin Caref/Google Drive/RScripts/Functions/eventfinder.rFunc")

#these two functions split up the neurons and the behavioral events for each experiment
neurons = lapply(seq(1, length(nexdata)), function(x) {
  neuronidx = grep("sig", names(nexdata[[x]]))
  nexdata[[x]][neuronidx] })
  
events = eventfinder.rFunc(nexdata, event) 


#specify the interval of timestamps you want to examine  
sstart = startt
send = endt

#specify whether to only return cue excited neurons
    

#########################################################
#these two functions simply restrict the timestamp values
#to the window specified above
#######################################################
neurons = lapply(seq(1, length(neurons)), function(x) {
  lapply(seq(1, length(neurons[[x]])), function(y) {
    neurons[[x]][[y]][which(neurons[[x]][[y]] >= sstart & neurons[[x]][[y]] <= send)]
   })
  })

events = lapply(seq(1, length(events)), function(x) {
   events[[x]][which(events[[x]] >= sstart & events[[x]] <= send)] })
  


#########################################################
#Now that the relevant data is extracted, we can begin to 
#analyze it by constructing rasters, histograms, etc.
#########################################################
#binsize = binw #in ms
winmin = 10 #in s
winmax = 1 #in s



#####################################################################
#This function returns a list of lists of lists:
#Level 1 is the experiment; Level 2 is each neuron in the experiment;
#Level 3 is the time relative to the specified event for each trial
#The object masterlist can then be used to construct PSTHs or rasters
########################################################################
masterlist = lapply(seq(1, length(neurons)), function(x) {
  lapply(seq(1, length(neurons[[x]])), function(y) {
    lapply(seq(1, length(events[[x]])), function(z) {
      stampsidx = which(neurons[[x]][[y]] >= events[[x]][z] - winmin & neurons[[x]][[y]] <= events[[x]][z] + winmax)
      relstamps = neurons[[x]][[y]][stampsidx] - events[[x]][z]
     })
    })    
   })



sigbins = lapply(seq(1, length(masterlist)), function(x) {
    lapply(seq(1, length(masterlist[[x]])), function(y) {    
    
    intmin = -10
    intmax = 1
    pbin = .05
    
    allvals = unlist(masterlist[[x]][[y]])
    hcounts = hist(allvals[which(allvals >= intmin & allvals <= intmax)], breaks = seq(intmin, intmax, pbin), plot = F)$counts
    
    baseline = hcounts[1:abs(intmin/pbin)]
    

#Applying Vince's code to my data
    premean = mean( (baseline / length(masterlist[[x]][[y]])) )   # find the mean fr per bin within the pre period    
    probvect = ppois(hcounts, premean*length(masterlist[[x]][[y]])) # the lambda argument is the mean fr per bin times the number of trials

    critwin = probvect[(abs(intmin/pbin)+1):(abs(intmin/pbin)+intmax/pbin)]


    sigbins = rep(F, length(critwin))
    sigbins[which(critwin <= .01)] = T
    

    
return(sigbins)

  })
 })
 
sigbindf = t(do.call("rbind", lapply(seq(1, length(sigbins)), function(x) do.call("rbind", sigbins[[x]])))) 
 
return(sigbindf)

}

save(KC.inhib.sigbins.Rfunc, file = "C:/Users/Kevin Caref/Google Drive/RScripts/Functions/KC inhib sigbins.Rfunc")


 