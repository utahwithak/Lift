#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "HTMLPreviewBuilder.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    @autoreleasepool {

        // Set up the object that creates the HTML preview
        HTMLPreviewBuilder *builder = [[HTMLPreviewBuilder alloc] init];

        NSString *html = [builder htmlPreviewForPath:(__bridge NSURL*)url];
        if(html == nil)
            return noErr;

        QLThumbnailRequestSetThumbnailWithDataRepresentation(thumbnail,
                                                             (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
                                                             kUTTypeHTML, NULL,NULL);
    }
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
