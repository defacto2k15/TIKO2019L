function GenerateRateOptionString($rateSetting, $libSetting, $aPassSetting, $instanceDescription, [ref]$x264Options, [ref]$x265Options, [ref]$ffmpegOptions, [ref]$outExtension){
    
    if($rateSetting.crf){
        $instanceDescription | add-member -type NoteProperty -Name ParameterCrfValue -Value $rateSetting.crf
        $ffmpegOptions.value += " -crf $($rateSetting.crf)"
        if($aPassSetting -eq 2){
            # TWO PASS CRF NOT SUPPORTED
            return $FALSE;
        }
    }
    
    if ($rateSetting.cbr){
        $rate=$rateSetting.cbr;

        $instanceDescription | add-member -type NoteProperty -Name ParameterCbrValue -Value $rateSetting.cbr
        if( $libSetting -eq 4 ){
            $ffmpegOptions.value += "-b:v $($rate)K", "-minrate $($rate)K", "-maxrate $($rate)K",  "-bufsize $($rate*2)K"
            $x264Options.value += "nal-hrd=cbr"
            $outExtension.value="ts";
        }else{
            ##$optionsString += " -b:v $($rate)K -minrate $($rate)K -maxrate $($rate)K -bufsize $($rate*2)K"
            ## NOT SUPPORTED
            return $FALSE;
        }
    }

    if($rateSetting.vbv){
        $rate=$rateSetting.vbv;
        $instanceDescription | add-member -type NoteProperty -Name ParameterVbvValue -Value $rate

        if( $libSetting -eq 4 ){
            $ffmpegOptions.value += "-maxrate $($rate)K", "-bufsize $($rate)K"
        } else{
            $x265Options.value += "vbv-maxrate=$($rate)", "vbv-bufsize=$(2*$rate)"
        }
    }

    if($rateSetting.abr){
        $rate=$rateSetting.abr;
        $instanceDescription | add-member -type NoteProperty -Name ParameterAbrValue -Value $rate
        $ffmpegOptions.value += "-b:v $($rate)K"
    }
    return $TRUE;
}

function GenerateParametersString($x264Options, $x265Options, $ffmpegOptions){
    $x264String = "";
    if($x264Options){
        $x264String = "-x264-params " + ($x264Options -join ':');
    }

    $x265String = "";
    if($x265Options){
        $x265String = "-x265-params " + ($x265Options -join ':');
    }

    "$( $ffmpegOptions -join ' ')  $x264String $x265String"
}


$ErrorActionPreference = "Inquire";
#cd C:\studiaMagisterskie\TIKO\projekt\testowanie
$inputVideoFile = "inputVideo.webm"

cls
rm .\output-*

$rateSettigns =  @{cbr=4000}, @{crf=24; vbv=500}, @{crf=24}, @{vbv=500}, @{abr=1000}
$libSettings = 4, 5 # 4 - x264 5 - x265
$passesSettings = 1, 2
$deblockSettings = @{deblock=$TRUE}# , @{deblock=$FALSE} 
$bframeSettings = 8# 0, 8, 32
$partitionSettings = "default"#, "all", "none"

$instanceDescriptions = @()
$generatedVideoIndex = 0;


foreach($aLibSetting in $libSettings){
foreach($aRateSetting in $rateSettigns){
foreach($aPassSetting in $passesSettings){
foreach($aDeblockSetting in $deblockSettings){
foreach($aBframeSetting in $bframeSettings){
foreach($aPartitionSetting in $partitionSettings){
    
    $thisInstanceIndex = $generatedVideoIndex;

    $instanceDescription = new-object PSObject
    $instanceDescription | add-member -type NoteProperty -Name Index -Value $thisInstanceIndex

    $x264Options=@()
    $x265Options=@()
    $selectedLibOptions=@()
    $ffmpegOptions=@()

    $outExtension = "mp4"

    $genResult = GenerateRateOptionString $aRateSetting $aLibSetting $aPassSetting  $instanceDescription ([ref]$x264Options) ([ref]$x265Options) ([ref]$ffmpegOptions) ([ref]$outExtension)
    if(-not $genResult){
        continue;
    }

    if($aDeblockSetting.deblock){
        $instanceDescription | add-member -type NoteProperty -Name Deblock -Value 1
    }else{
        $instanceDescription | add-member -type NoteProperty -Name Deblock -Value 0
        $selectedLibOptions += "no-deblock=1"    
    }

    $selectedLibOptions += "bframes=$aBframeSetting"
    $instanceDescription | add-member -type NoteProperty -Name Bframes -Value $aBframeSetting

    $instanceDescription | add-member -type NoteProperty -Name Partitions -Value $aPartitionSetting
    if($aPartitionSetting -eq "default" ){
    }else{
        $selectedLibOptions += "partitions=$aPartitionSetting"    
    }

    $instanceDescription | add-member -type NoteProperty -Name LibVersion -Value $aLibSetting
    if($aLibSetting -eq 4 ){
        $x264Options += $selectedLibOptions
        $ffmpegOptions += "-c:v libx264"
    }elseif($aLibSetting -eq 5){
        $x265Options += $selectedLibOptions
        $ffmpegOptions += "-c:v libx265"
    }

    $outFileName = "output-$thisInstanceIndex.$outExtension"
    $instanceDescription | add-member -type NoteProperty -Name FileName -Value $outFileName

    $command = "";
    $instanceDescription | add-member -type NoteProperty -Name PassCount -Value $aPassSetting




    if($aPassSetting -eq 1){
        $command = "ffmpeg -i $inputVideoFile  $(GenerateParametersString $x264Options $x265Options $ffmpegOptions) -y $outFileName"
    }else{

        $extraOpt1 = "";
        $extraOpt2 = "";
        if($aLibSetting -eq 5){
            $statsPath = (pwd).Path + "\mylog.log" 
            $extraOpt1 = $(GenerateParametersString $x264Options ($x265Options + "pass=1:stats=`"$statsPath`""  ) $ffmpegOptions) 
            $extraOpt2 = $(GenerateParametersString $x264Options ($x265Options + "pass=2:stats=`"$statsPath`""  ) $ffmpegOptions) 
            
        }else{
            $extraOpt1 = $(GenerateParametersString $x264Options $x265Options  $ffmpegOptions) 
            $extraOpt2 = $extraOpt1
        }

        $command =  "bin/ffmpeg.exe -i $inputVideoFile $extraOpt1 -y -pass 1  -f null -; "
        $command += "bin/ffmpeg.exe -i $inputVideoFile $extraOpt2 -y -pass 2 $outFileName 2>&1"
    }


    $measurement = Measure-Command -Expression { $ErrorActionPreference = "Continue"; iex $command; $ErrorActionPreference = "Inquire";}
    $encodingTime = $measurement.TotalSeconds
    $instanceDescription | add-member -type NoteProperty -Name EncodingTime -Value $encodingTime


    echo $generatedVideoIndex

    $POutText = bin/ffprobe.exe -v quiet -print_format json -show_format $outFileName 2>&1
    $probeObject = [system.String]::Join(" ",$POutText) | ConvertFrom-Json

    $outBitrate = $probeObject.format.bit_rate
    $instanceDescription | add-member -type NoteProperty -Name OutBitrate -Value $outBitrate
    $fileSize = $probeObject.format.size
    $instanceDescription | add-member -type NoteProperty -Name FileSize -Value $fileSize

    # ////////// Setting instance properties ////////
    $ErrorActionPreference = "Continue"
    $BOutText =  bin/ffmpeg.exe  -i $outFileName -benchmark -f null - 2>&1
    $ErrorActionPreference = "Inquire"
    $decodingTime = $BOutText[-2] -replace "[^0-9.]";
    $instanceDescription | add-member -type NoteProperty -Name DecodingTime -Value $decodingTime
    $decodingMem =  $BOutText[-1] -replace "[^0-9]"
    $instanceDescription | add-member -type NoteProperty -Name DecodingMem -Value $decodingMem

    echo $BOutText

    $instanceDescriptions += $instanceDescription


    $generatedVideoIndex++;
}
}
}
}
}
}

$props = $instanceDescriptions | ForEach-Object {$_.PSObject.Properties.Name} | select -uniq
foreach($aProp in $props){
    if( -not [bool]($instanceDescriptions[0].PSobject.Properties.name -match $aProp)){
         $instanceDescriptions[0] | add-member -type NoteProperty -Name $aProp -Value ""
    } 
}

$instanceDescriptions | Export-Csv -Path .\VideoInfos.csv 