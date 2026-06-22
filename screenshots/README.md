Screenshots folder

This folder should contain the required screenshots for project submission.

Expected filenames:

- screenshots/home.png
- screenshots/product_detail.png
- screenshots/cart.png

If you want quick placeholder PNGs, you can create them from this 1x1 transparent PNG base64 string.

PowerShell example (run in project root):

```powershell
$base64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAn8B9U3GqQAAAABJRU5ErkJggg=='
[System.Convert]::FromBase64String($base64) | Set-Content -Encoding Byte screenshots/home.png
[System.Convert]::FromBase64String($base64) | Set-Content -Encoding Byte screenshots/product_detail.png
[System.Convert]::FromBase64String($base64) | Set-Content -Encoding Byte screenshots/cart.png
```

Replace these placeholders with actual screenshots before final submission.
