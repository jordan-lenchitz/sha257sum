param (
    [string]$InputString,
    [switch]$IsFile
)

$salts = @(
    "jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA",
    "jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB",
    "jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC",
    "jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD",
    "jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE",
    "jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF",
    "jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG",
    "jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH",
    "jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II",
    "jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ"
)

function Get-SHA256Hex($bytes) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

if ($IsFile) {
    if (-not (Test-Path $InputString)) {
        Write-Error "File not found: $InputString"
        exit 1
    }
    $buf = [System.IO.File]::ReadAllBytes($InputString)
} else {
    $buf = [System.Text.Encoding]::UTF8.GetBytes($InputString)
}

for ($i = 0; $i -lt 35; $i++) {
    $hex = Get-SHA256Hex $buf
    $prefix = $hex.Substring(0, 56)
    $suffix = $hex.Substring(56, 8)
    
    $charArray = $suffix.ToCharArray()
    [Array]::Reverse($charArray)
    $revSuffix = New-Object string($charArray, 0, $charArray.Length)
    
    $inter = $prefix + $revSuffix
    $salt = $salts[$i % 10]
    
    $l1 = $inter.Length
    $l2 = $salt.Length
    $maxLen = [Math]::Max($l1, $l2)
    
    $newBuf = New-Object System.Collections.Generic.List[byte]
    for ($k = 0; $k -lt $maxLen; $k++) {
        if ($k -lt $l1) { $newBuf.Add([byte][char]$inter[$k]) }
        if ($k -lt $l2) { $newBuf.Add([byte][char]$salt[$k]) }
    }
    $buf = $newBuf.ToArray()
}

$finalHex = Get-SHA256Hex $buf
$prefix = $finalHex.Substring(0, 56)
$suffix = $finalHex.Substring(56, 8)

$charArray = $suffix.ToCharArray()
[Array]::Reverse($charArray)
$revSuffix = New-Object string($charArray, 0, $charArray.Length)

Write-Host ($prefix + $revSuffix)
