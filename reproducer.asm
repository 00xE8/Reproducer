format pe console
entry start

include 'win32ax.inc'




section '.text' code writeable executable 
start:

	invoke	GdiplusStartup,token,input,NULL 
		test	 eax,eax 
		jnz	 exit 

    invoke  GdipGetImageEncodersSize,encoders_count,encoders_size 
        test    eax,eax 
	    jnz	   gdiplus_shutdown
	
	;Below create an empty buffer
	invoke  VirtualAlloc,0,[encoders_size],MEM_COMMIT,PAGE_READWRITE 
        test    eax,eax 
        jz      gdiplus_shutdown 
		mov     ebx,eax 
	;Below use buffer created above
    invoke  GdipGetImageEncoders,[encoders_count],[encoders_size],ebx 
		test    eax,eax 
		jnz     gdiplus_shutdown 

scan_encoders: 
		mov     esi,[ebx+ImageCodecInfo.MimeType] 
		mov     edi,encoder_mimetype 
        mov     ecx,11 
		repe    cmpsw 
		je      encoder_found 
		add     ebx,sizeof.ImageCodecInfo 
		dec     [encoders_count] 
		jnz     scan_encoders 
       ; no encoder found 
	   ; no encoder found
		jmp     gdiplus_shutdown
	 
encoder_found: 
		lea     esi,[ebx+ImageCodecInfo.Clsid] 
		mov     edi,encoder_clsid 
		mov     ecx,4 
		rep     movsd 
    invoke  VirtualFree,ebx,0,MEM_RELEASE 

	invoke  GetDC,HWND_DESKTOP 
		test    eax,eax 
		jz      gdiplus_shutdown 
		mov     esi,eax 
    invoke  GetSystemMetrics,SM_CYSCREEN 
        mov     [screen_height],eax 
	invoke  GetSystemMetrics,SM_CXSCREEN 
        mov     [screen_width],eax 
	invoke  CreateCompatibleBitmap,esi,[screen_width],[screen_height] 
		test    eax,eax 
		jz      release_desktop_dc 
		mov     ebx,eax 
    invoke  CreateCompatibleDC,esi 
		test    eax,eax 
		jz      delete_bitmap 
		mov     edi,eax 
    invoke  SelectObject,edi,ebx 
        test    eax,eax 
		jz      delete_dc 
	invoke  BitBlt,edi,0,0,[screen_width],[screen_height],esi,0,0,SRCCOPY 
		test    eax,eax 
		jz      delete_dc 

    invoke  GdipCreateBitmapFromHBITMAP,ebx,NULL,gdip_bitmap 
		test    eax,eax 
		jnz     delete_dc 

    invoke  GdipSaveImageToFile,[gdip_bitmap],file_name,encoder_clsid,NULL 

	invoke  GdipDisposeImage,[gdip_bitmap]
	
release_desktop_dc: 
    invoke  ReleaseDC,HWND_DESKTOP,esi 

delete_dc: 
	invoke  DeleteObject,edi 

delete_bitmap: 
    invoke  DeleteObject,ebx 
	
gdiplus_shutdown: 
	invoke	GdiplusShutdown,[token]   
    invoke ExitProcess, 0

exit: 
    invoke  ExitProcess,0 

	
	
 section '.data' data readable writeable 
 encoder_mimetype du 'image/jpeg',0
 encoder_clsid db 16 dup ?
 memdc dd ? 
 gdip_bitmap dd ?
 file_name du 'test.jpg',0

 struct GdiplusStartupInput 
   GdiplusVersion     dd ? 
   DebugEventCallback	dd ? 
   SuppressBackgroundThread dd ?  
   SuppressExternalCodecs   dd ? 
 ends 

 struct ImageCodecInfo 
   Clsid      db 16 dup ? 
   FormatID	 db 16 dup ? 
   CodecName	 dd ? 
   DllName	dd ? 
   FormatDescription dd ? 
   FilenameExtension dd ? 
   MimeType	dd ? 
   Flags 	dd ? 
   Version	dd ? 
   SigCount	dd ? 
   SizeSize	dd ? 
   SigPattern		dd ? 
   SigMask	dd ? 
 ends 

   input GdiplusStartupInput 1 
   token dd ? 
   text du ?


   encoders_count dd ? 
   encoders_size dd ? 

   screen_width dd ? 
   screen_height dd ? 
   msg dd ?
    
	
	

section '.rdata' data readable

data import 

  library kernel32,'KERNEL32.DLL',\ 
      user32,'USER32.DLL',\ 
	  gdi32,'GDI32.DLL',\ 
      gdiplus, 'GDIPLUS.DLL' 

  include 'api\kernel32.inc' 
  include 'api\user32.inc' 
  include 'api\gdi32.inc' 
  import  gdiplus,\ 
	  GdiplusStartup,'GdiplusStartup',\ 
	  GdiplusShutdown,'GdiplusShutdown',\ 
      GdipGetImageEncodersSize,'GdipGetImageEncodersSize',\ 
      GdipGetImageEncoders,'GdipGetImageEncoders',\ 
      GdipSaveImageToFile,'GdipSaveImageToFile',\ 
      GdipDisposeImage,'GdipDisposeImage',\ 
      GdipCreateBitmapFromHBITMAP,'GdipCreateBitmapFromHBITMAP' 

end data