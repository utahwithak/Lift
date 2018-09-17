#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "HTMLPreviewBuilder.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool {

        // Load the property list from the URL
        // Set up the object that creates the HTML preview
        HTMLPreviewBuilder *builder = [[HTMLPreviewBuilder alloc] init];
        // Generate a preview for this plist and retrieve it as a string
        // (Begin recursive preview generation by wrapping the plist's top level object in a dictionary)
        NSString *html = [builder htmlPreviewForPath:(__bridge NSURL*)url];
        NSLog(@"PREVIEW HTML: %@", html);
        if(html == nil)
            return noErr;

        // Pass preview data and metadata/attachment dictionary to QuickLook
        QLPreviewRequestSetDataRepresentation(preview,
                                              (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
                                              kUTTypeHTML,
                                              NULL);
    }
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
