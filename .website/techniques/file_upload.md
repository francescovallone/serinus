# File upload

To handle file uploading, Serinus provides a built-in way to manage multipart/form-data requests. The body of such requests will be parsed as a `FormData` object, which contains both fields and files.

## Basic Example

```dart
import 'package:serinus/serinus.dart';

class UploadController extends Controller {
  UploadController() : super('/upload') {
    on(Route.post('/'), (RequestContext<FormData> context) async {
      final formData = context.body;

      // Access fields
      final name = formData.fields['name'];

      // Access files
      final uploadedFile = formData.file('file'); // Returns an UploadedFile
      if (uploadedFile != null) {
        // Sanitize filename to prevent directory traversal attacks
        final sanitizedFileName = uploadedFile.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
        // You can also generate a unique filename here
        // final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${uploadedFile.name.split('/').last.split('\\').last}';
        final file = await uploadedFile.toFile('/path/to/save/$sanitizedFileName');
        // Process the file content as needed
      }

      return 'File uploaded successfully';
    });
  }
}
```

## Accessing Uploaded Files

You can access uploaded files using the `file` method on the `FormData` object. This method returns an `UploadedFile`. An `UploadedFile` provides the following properties and methods:

| Property/Method | Description                                      |
|-----------------|--------------------------------------------------|
| `name`          | The name of the uploaded file.                   |
| `contentType`   | The content type of the uploaded file.           |
| `stream`        | A stream of bytes representing the file content. |
| `read()`        | Reads the entire file content into memory.       |
| `toFile(path)`  | Saves the uploaded file to the specified path.   |

## Security Considerations

When handling file uploads, always validate and sanitize user input:

- **Validate file type**: Check the `contentType` against an allowlist
- **Limit file size**: Enforce maximum file size limits
- **Sanitize filenames**: Remove or replace path separators and special characters
- **Use unique filenames**: Generate server-side filenames to avoid conflicts and attacks
- **Store outside web root**: Save uploaded files outside publicly accessible directories
