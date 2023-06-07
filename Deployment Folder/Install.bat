if not exist "C:\Windows\System32\Scripts\Toasty's PowerTools" md "C:\Windows\System32\Scripts\Toasty's PowerTools"
XCOPY /y /e "\\awv-wad-s-ccm02\Deployment Share\Applications\Toasty's PowerTools\PS\*.*" "C:\Windows\System32\Scripts\Toasty's PowerTools"
XCOPY /y "\\awv-wad-s-ccm02\Deployment Share\Applications\Toasty's PowerTools\Toasty's PowerTools.lnk" "C:\Users\Public\Desktop"
XCOPY /y "\\awv-wad-s-ccm02\Deployment Share\Applications\Toasty's PowerTools\PS\V1.txt" "C:\Windows\System32\Scripts\Toasty's PowerTools"