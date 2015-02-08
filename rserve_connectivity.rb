
require "rserve"


module AAA

  TEST_RESULT='''
    jpeg(file="#{file_name}")
    setwd("/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test_datasets")
    library("ggplot2", lib.loc="/Library/Frameworks/R.framework/Versions/3.1/Resources/library")
    d= read.csv("/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test_datasets/11-1_ipi__3787-11_HP_IM3_9_[35079.4,16748]_cell_seg_data.csv", stringsAsFactors=FALSE)
    w=summary(factor(d$phenotype))
    w=data.frame(w)
    print(qplot(rownames(w), w$w)+coord_flip()+ylab("counts")+xlab("cell types"))
    dev.off()
  '''

end



$script=<<-EOF
  #{2+44}
  png(file='/Users/sausheong/projects/wavform/mrtplot.png', height=800, width=600, res=72)
  par(mfrow=c(3,1),cex=1.1)
  wav_data <- read.csv(file='/Users/sausheong/projects/wavform/wavdata.csv', header=TRUE)
  plot(wav_data$combined, type='n', main='Channel 1', xlab='Time', ylab='Frequency')
  lines(wav_data$ch1)
  plot(wav_data$combined, type='n', main='Channel 2', xlab='Time', ylab='Frequency')
  lines(wav_data$ch2)
  plot(wav_data$combined, type='n', main='Channel 1 + Channel 2', xlab='Time', ylab='Frequency')
  lines(wav_data$combined)
  dev.off()
EOF
#
#Rserve::Connection.new.eval(script)


$script2=<<EOF
svg('/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test.svg')
setwd("/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test_datasets")
library("ggplot2", lib.loc="/Library/Frameworks/R.framework/Versions/3.1/Resources/library")
`11.1_ipi__3787.11_HP_IM3_9_[35079.4,16748]_cell_seg_data` <- read.csv("/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test_datasets/11-1_ipi__3787-11_HP_IM3_9_[35079.4,16748]_cell_seg_data.csv", stringsAsFactors=FALSE)
w=summary(factor(d$phenotype))
w=data.frame(w)
qplot(rownames(w), w$w)
dev.off()
EOF


$script3=<<EOF
pdf(file="/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test.pdf")
setwd("/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test_datasets")
library("ggplot2", lib.loc="/Library/Frameworks/R.framework/Versions/3.1/Resources/library")
d= read.csv("/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/test_datasets/11-1_ipi__3787-11_HP_IM3_9_[35079.4,16748]_cell_seg_data.csv", stringsAsFactors=FALSE)
w=summary(factor(d$phenotype))
w=data.frame(w)
print(qplot(rownames(w), w$w)+coord_flip()+ylab("counts")+xlab("cell types"))
dev.off()
EOF

$script4=<<EOF
pdf(file="/Users/carlobifulco/Dropbox/path/path_research/BMS_NY_PE_Relationships/plots.pdf", width=11, height=8.5)
plot(1,2)
dev.off()
EOF
