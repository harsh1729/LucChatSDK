# SwiftUTI

A swift wrapper around Apples Universal Type Identifier functions.

## Usage

A typical usage might be like that:

```Swift
let fileURL = URL(fileURLWithPath: ...)
let fileUTI = UTI(withExtension: fileURL.pathExtension)

// Check if it is a specific UTI (UTIs are equatable):

if fileUTI == UTI.pdf {

    // handle PDF document...
}

// Check if an UTI conforms to a UTI:

if fileUTI.conforms(to: .image) {

    // Handle image file...
}
```

## Creating  System and Custom UTIs

All system defined `UTType`s are available as static variables. For example, to access the UTType for PDF documents, simply call `UTI.pdf`.

To define your own UTI (perhaps for your custom document type), you should make an extension like this:

```Swift
public extension UTI {

    static let myDocument = UTI(rawValue: "com.mycompany.mydocument")
}
```

Your custom type is then accessible like this: `UTI.myDocument`.

##Tags

You can easily create UTIs from any tag class, as well as access tags from an UTI instance.  For example to get the MIME type of PDFs, simply call `UTI.pdf.mimeType`.

