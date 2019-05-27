library(RColorBrewer)
library(ggplot2)
library(RPMG)

setwd("C:\\studiaMagisterskie\\TIKO\\projekt\\wykresy")

savePlot <- function(filename, plot){
  ggsave(paste("plots/", filename, ".png", sep=""), plot=plot)
  #print(plot)
}

toHumanReadableBytes <- function(n){ #TODO wieksza dokladnosc!!!
  suffix <- ""
  if( n < 1000 ){
    suffix <- "B";
  }else{
    n <- (n/1000.0 )
    if( n < 1000 ){
      suffix <- "KB";
    }else{
      n <- (n/1000.0 )
      suffix <- "MB";
    }
  }
  
  paste( signif(n,2), suffix) 
}

toHumanReadableLibVersion <- function(n){
  if( n == 4){
    "x264"
  }else if (n == 5){
    "x265"
  }else{
    "?"
  }
  
}

ankieta = read.csv("ankieta.csv")
generationParams = read.csv("generationParams.csv")
generationParams$ParameterAbrValue <- generationParams$ParameterAbrValue*1024
generationParams$ParameterCbrValue <- generationParams$ParameterCbrValue*1024
generationParams$ParameterVbvValue <- generationParams$ParameterVbvValue*1024

# abrGenerationParams <- generationParams[  !is.na(generationParams$ParameterAbrValue) & is.na(generationParams$ParameterVbvValue),]

#ad <- abrGenerationParams# data.frame( abrGenerationParams$FileName, abrGenerationParams$ParameterAbrValue, abrGenerationParams$LibVersion, abrGenerationParams$OutBitrate, abrGenerationParams$DecodingUTime)
#colnames(ad) <- c("FileName", "ParameterAbrValue", "LibVersion","OutBitrate", "DecodingUTime")
generationParams$NamedBitrate <-  unlist(lapply(generationParams$OutBitrate, toHumanReadableBytes), use.names=FALSE)
generationParams$NamedLibVersion <-  unlist(lapply(generationParams$LibVersion, toHumanReadableLibVersion), use.names=FALSE)

scoresDf <- data.frame(matrix(ncol = 2, nrow = 0))
colnames(scoresDf) <- c("FileName", "Score")

for( i in 1:nrow(ankieta)){
  name <-  toString(ankieta[i,]$FileName)
  r <- (as.vector( t( ankieta[i,2:ncol(ankieta)])))
  r <- r[!is.na(r)]
  
  for( z in r){
    scoresDf[nrow(scoresDf) + 1,] = list(name, z)
  }
}

codingType =  vector(mode="character", length=nrow(generationParams))
for( i in 1:nrow(generationParams)){
  r <- generationParams[i,];
  if(!is.na(r$ParameterAbrValue)){
    if(!is.na(r$ParameterVbvValue)){
      codingType[i] <- "ABR-VBV"
    }else{
      codingType[i] <- "ABR"
    }
  }else if (!is.na(r$ParameterCrfValue)){
    if(!is.na(r$ParameterVbvValue)){
      codingType[i] <- "CRF-VBV"
    }else{
      codingType[i] <- "CRF"
    }
  }else if (!is.na(r$ParameterCbrValue)){
    codingType[i] <- "CBR"
  }
}
generationParams$codingType <- codingType

generationParams <- merge(scoresDf, generationParams)

generateBitrateScorePlot <- function( ad, paramName, paramValues){
  # Bitrate - Score
  breaks <- 100000 * c(1,2,5, 10, 20, 50, 100)
  theme_set(theme_bw())
  p <- ggplot(ad, aes( y=ad$Score, x=(ad$OutBitrate), group=NamedLibVersion)) + 
    geom_jitter(aes(col=NamedLibVersion ), size=2, width=0, height=0.2, alpha = 0.5)   +
    geom_smooth(aes(col=NamedLibVersion), method="lm", formula=y ~ splines::bs(x, 3), se=F) + 
    scale_x_log10(breaks = breaks,  labels = lapply(breaks, toHumanReadableBytes))  +
    annotation_logticks(sides="b")  +
    guides(fill=FALSE) +
    labs(title = paste(paramName,"- Bitrate a ocena"),
         x = "Bitrate  (na sekunde)",
         y = "Ocena",
         colour="Biblioteka") 
  
  savePlot(paste(paramName,"Bitrate-Score"),p)
}

generateBitrateKbParameterPlot <- function( ad, paramName, paramValues){
  # Bitrate-ParameterAbr
  breaks <- 100000 * c(1,2,5, 10, 20, 50, 100)
  yScale = seq(100)
  p <- ggplot(ad, aes( y=OutBitrate, x=(paramValues), group=NamedLibVersion)) + 
    geom_jitter(aes(col=NamedLibVersion ), size=2, width=0, height=0.2, alpha = 0.5)   +
    geom_smooth(aes(col=NamedLibVersion), method="lm", formula=y ~ splines::bs(x, 3), se=F) +
    scale_y_log10(breaks = breaks, labels = lapply(breaks, toHumanReadableBytes)) +
    scale_x_log10(breaks = breaks, labels = lapply(breaks, toHumanReadableBytes)) +
    annotation_logticks(sides="lb")  +
    guides(fill=FALSE) +
    labs(title = paste(paramName,"- Bitrate osiagniety a wymagany"),
         y = "Bitrate osiagniety (na sekunde)",
         x = "Bitrate wymagany (na sekunde)",
         colour="Biblioteka") 

  savePlot(paste(paramName,"Bitrate-Parameter"),p)
}

generateBitrateCrfParameterPlot <- function( ad, paramName, paramValues){
  # Bitrate-ParameterAbr
  breaks <- 100000 * c(1,2,5, 10, 20, 50, 100)
  yScale = seq(100)
  p <- ggplot(ad, aes( y=OutBitrate, x=(paramValues), group=NamedLibVersion)) + 
    geom_jitter(aes(col=NamedLibVersion ), size=2, width=0, height=0.2, alpha = 0.5)   +
    geom_smooth(aes(col=NamedLibVersion), method="lm", formula=y ~ splines::bs(x, 3), se=F) +
    scale_y_log10(breaks = breaks, labels = lapply(breaks, toHumanReadableBytes)) +
    scale_x_continuous() +
    annotation_logticks(sides="l")  +
    guides(fill=FALSE) +
    labs(title = paste(paramName,"- Bitrate osiagniety a wymagana jakosc"),
         x = "Wymagana jakosc",
         y = "Bitrate osiagniety (na sekunde)",
         colour="Biblioteka") 
  savePlot(paste(paramName,"Bitrate-CrfParameter"),p)
}

generateBitrateTimePlot <- function( ad, paramName, paramValues){
  # Bitrate - Time
  breaks <- 100000 * c(1,2,5, 10, 20, 50, 100)
  
  p <- ggplot(ad, aes( y=DecodingUTime, x=(OutBitrate), fill=NamedLibVersion)) + 
    geom_jitter(aes(col=NamedLibVersion ), size=2, width=0, height=0.2, alpha = 0.5)   +
    geom_smooth(aes(col=NamedLibVersion), method="lm", formula=y ~ splines::bs(x, 3), se=F) +
    scale_x_log10(breaks = breaks, labels = lapply(breaks, toHumanReadableBytes))  +
    annotation_logticks(sides="b") +
    guides(fill=FALSE) +
    labs(title = paste(paramName,"- Bitrate a czas kodowania"),
         x = "Bitrate (na sekunde)",
         y = "Czas kodowania w sekundach",
         colour="Biblioteka") 
  savePlot(paste(paramName,"Bitrate-Time"),p)
}

generateStandardPlots <- function( ad, paramName, paramValues){
  generateBitrateScorePlot(ad, paramName, paramValues)
  generateBitrateKbParameterPlot(ad, paramName, paramValues)
  generateBitrateTimePlot(ad, paramName, paramValues)
}

generateCrfPlots <- function( ad, paramName, paramValues){
  generateBitrateScorePlot(ad, paramName, paramValues)
  generateBitrateCrfParameterPlot(ad, paramName, paramValues)
  generateBitrateTimePlot(ad, paramName, paramValues)
}



t1 <- generationParams[!is.na(generationParams$ParameterAbrValue) & is.na(generationParams$ParameterVbvValue),]
generateStandardPlots(t1, "ABR", t1$ParameterAbrValue)

t1 <- generationParams[!is.na(generationParams$ParameterAbrValue) & !is.na(generationParams$ParameterVbvValue),]
generateStandardPlots(t1, "ABR-VBV", t1$ParameterAbrValue)

t1 <- generationParams[!is.na(generationParams$ParameterCbrValue) & is.na(generationParams$ParameterVbvValue),]
generateStandardPlots(t1, "CBR", t1$ParameterCbrValue)

t1 <- generationParams[!is.na(generationParams$ParameterCrfValue) & is.na(generationParams$ParameterVbvValue),]
generateCrfPlots(t1, "CRF", t1$ParameterCrfValue)

t1 <- generationParams[!is.na(generationParams$ParameterCrfValue) & !is.na(generationParams$ParameterVbvValue),]
generateCrfPlots(t1, "CRF-VBV", t1$ParameterCrfValue)

#Gigantyczny bitrate-jakosc 

breaks <- 100000 * c(1,2,5, 10, 20, 50, 100)

p <- ggplot(generationParams, aes( y=generationParams$Score, x=generationParams$OutBitrate, 
                                   group=interaction(NamedLibVersion, codingType ), color=codingType, linetype=NamedLibVersion)) +
  geom_jitter( size=2, width=0, height=0.2, alpha = 0.5)   +
  geom_smooth( method="lm", formula=y ~ splines::bs(x, 3), se=F ) +
  scale_x_log10(breaks = breaks,  labels = lapply(breaks, toHumanReadableBytes))  +
  annotation_logticks(sides="b")  +
  guides(fill=FALSE) +
  labs(title = "Podsumowanie - Bitrate a ocena",
       x = "Bitrate  (na sekunde)",
       y = "Ocena",
       colour="Metoda kodowania", linetype="Biblioteka")
savePlot("Summary-Bitrate-Score",p)



p <- ggplot(generationParams, aes( y=generationParams$DecodingUTime, x=generationParams$OutBitrate, 
                                   group=interaction(NamedLibVersion, codingType ), color=codingType, linetype=NamedLibVersion)) +
  geom_jitter( size=2, width=0, height=0.2, alpha = 0.5)   +
  geom_smooth( method="lm", formula=y ~ splines::bs(x, 3), se=F ) +
  scale_x_log10(breaks = breaks,  labels = lapply(breaks, toHumanReadableBytes))  +
  annotation_logticks(sides="b")  +
  guides(fill=FALSE) +
  labs(title = "Podsumowanie - Czas kodowania a bitrate",
       x = "Bitrate (na sekunde)",
       y = "Czas kodowania (sekundy)",
       colour="Metoda kodowania", linetype="Biblioteka")
savePlot("Summary-Time-Bitrate",p)

breaks <- 100000 * c(1,2,5, 10, 20, 50, 100)
p <- ggplot(generationParams, aes( y=generationParams$DecodingUTime, x=generationParams$Score, 
                                   group=interaction(NamedLibVersion, codingType ), color=codingType, linetype=NamedLibVersion)) +
  geom_jitter( size=2, width=0, height=0.2, alpha = 0.5)   +
  geom_smooth( method="lm", formula=y ~ splines::bs(x, 3), se=F ) +
  guides(fill=FALSE) +
  labs(title = "Podsumowanie - Czas kodowania a ocena",
       y = "Czas kodowania (sekundy)",
       x = "Ocena",
       colour="Metoda kodowania", linetype="Biblioteka")
savePlot("Summary-Time-Score",p)
