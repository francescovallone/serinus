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
	  final uploadedFile = formData.file('file'); // This returns an UploadedFile?
	  if (uploadedFile != null) {
		final file = await uploadedFile.toFile('/path/to/save/${uploadedFile.name}');
		// Process the file content as needed
	  }

	  return 'File uploaded successfully';
	});
  }
}
```

## Accessing Uploaded Files

You can access uploaded files using the `file` method on the `FormData` object. This method returns an `UploadedFile`. An `UploadedFile` provides the following properties and methods:

| Property/Method | Description |
|-----------------|-------------|
| `name`          | The name of the uploaded file. |
| `contentType`  | The content type of the uploaded file. |
| `stream`       | A stream of bytes representing the file content. |
| `read()`       | Reads the entire file content into memory. |
| `toFile(path)` | Saves the uploaded file to the specified path. |

