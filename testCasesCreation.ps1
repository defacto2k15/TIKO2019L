cd C:\studiaMagisterskie\TIKO\projekt\new_all_videos
$allFiles = ls

rm  C:\studiaMagisterskie\TIKO\projekt\testCases\*

$s = @{}

for($i = 0; $i -lt 6; $i++){
    $s[$i] = $allFiles[( 0..59 | Where-Object { $_ % 6 -eq $i} ) ]
}

$testCases = @()

for($q = 0; $q -lt 3; $q++){
for($i = 0; $i -lt 10; $i++){ #testCaseIndex
    $thisCase = @()

    for($j = 0; $j -lt 6; $j++){
        $thisCase += $s[$j][ ($i + ($q*$j) + $j ) % 10]
    }



    $testCases += $thisCase
}
}

$casesCount = $testCases.Count / 6

foreach( $testCaseIndex in (0..($casesCount-1) ) ){
    mkdir "C:\studiaMagisterskie\TIKO\projekt\testCases\case$testCaseIndex"
    foreach( $fIndex in (0..5)  ){
        $fName = $testCases[  ($testCaseIndex*6) + $fIndex];
        $fileNumber = $allFiles.IndexOf( ($allFiles | Where-Object{ $_.Name -eq  $fName.Name } ) )

        #cp $fName "C:\studiaMagisterskie\TIKO\projekt\testCases\case$testCaseIndex\$fileNumber$($fName.Extension)"
        cp $fName "C:\studiaMagisterskie\TIKO\projekt\testCases\case$testCaseIndex\$($fName.Name)"
    }

}

