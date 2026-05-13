$json = Get-Content -Raw -Path "blog_fetch_output.json" -Encoding Unicode | ConvertFrom-Json
$content = New-Object System.Collections.Generic.List[string]
$content.Add("# $($json.title)")
$content.Add("URL: $($json.url)")
$content.Add("Description: $($json.meta_description)")
$content.Add("")
foreach ($h in $json.headings) { $content.Add(("#" * $h.level) + " " + $h.text) }
$content.Add("")
foreach ($p in $json.paragraphs) { $content.Add($p); $content.Add("") }
if ($json.code_blocks) { foreach ($cb in $json.code_blocks) { $content.Add("```$($cb.language)"); $content.Add($cb.code); $content.Add("```"); $content.Add("") } }
Set-Content -Path "blog_fetch_output.extracted.md" -Value $content -Encoding utf8
