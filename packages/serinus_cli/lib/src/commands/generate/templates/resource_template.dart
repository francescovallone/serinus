import 'package:mason/mason.dart';

MasonBundle generateResourceTemplate(String name){
  return MasonBundle.fromJson({
    'files': [
      {
        'path': '${name}_controller.dart',
        'data': 'aW1wb3J0ICdwYWNrYWdlOnNlcmludXMvc2VyaW51cy5kYXJ0JzsKCmltcG9ydCAne3tuYW1lfX1fc2VydmljZS5kYXJ0JzsKCkBDb250cm9sbGVyKCd7e25hbWV9fScpCmNsYXNzIHt7bmFtZS5wYXNjYWxDYXNlKCl9fUNvbnRyb2xsZXIgZXh0ZW5kcyBTZXJpbnVzQ29udHJvbGxlcnsKCiAgZmluYWwgTG9nZ2VyIF9sb2dnZXIgPSBMb2dnZXIoJ3t7bmFtZX19Jyk7CgogIHt7bmFtZS5wYXNjYWxDYXNlKCl9fVNlcnZpY2Ugc2VydmljZTsKCiAge3tuYW1lLnBhc2NhbENhc2UoKX19Q29udHJvbGxlcih0aGlzLnNlcnZpY2UpOwoKICBAR2V0KCkKICBTdHJpbmcgZ2V0KCkgewogICAgX2xvZ2dlci5pbmZvKCdHRVQgcmVxdWVzdCcpOwogICAgcmV0dXJuIHNlcnZpY2UuaGVsbG8oKTsKICB9CgogIEBQb3N0KCkKICBTdHJpbmcgcG9zdCgpIHsKICAgIHJldHVybiBzZXJ2aWNlLmhlbGxvKCk7CiAgfQoKICBAUHV0KHBhdGg6ICc6aWQnKQogIFN0cmluZyBwdXQoQFBhcmFtKCdpZCcpIFN0cmluZyBpZCkgewogICAgcmV0dXJuIGlkOwogIH0KCiAgQERlbGV0ZShwYXRoOiAnOmlkJykKICBTdHJpbmcgZGVsZXRlKEBQYXJhbSgnaWQnKSBTdHJpbmcgaWQpIHsKICAgIHJldHVybiBpZDsKICB9Cgp9',
        'type': 'text'
      },
      {
        'path': '${name}_service.dart',
        'data': 'aW1wb3J0ICdwYWNrYWdlOnNlcmludXMvc2VyaW51cy5kYXJ0JzsKCmNsYXNzIHt7bmFtZS5wYXNjYWxDYXNlKCl9fVNlcnZpY2UgZXh0ZW5kcyBTZXJpbnVzUHJvdmlkZXJ7CgogIFN0cmluZyBoZWxsbygpID0+ICdIZWxsbyBXb3JsZCEnOwoKfQ==',
        'type': 'text'
      },
      {
        'path': '${name}_module.dart',
        'data': 'aW1wb3J0ICdwYWNrYWdlOnNlcmludXMvc2VyaW51cy5kYXJ0JzsKCmltcG9ydCAne3tuYW1lfX1fY29udHJvbGxlci5kYXJ0JzsKaW1wb3J0ICd7e25hbWV9fV9zZXJ2aWNlLmRhcnQnOwoKQE1vZHVsZSgKICBpbXBvcnRzOiBbXSwKICBjb250cm9sbGVyczogW3t7bmFtZS5wYXNjYWxDYXNlKCl9fUNvbnRyb2xsZXJdLAogIHByb3ZpZGVyczogW3t7bmFtZS5wYXNjYWxDYXNlKCl9fVNlcnZpY2VdLAopCmNsYXNzIHt7bmFtZS5wYXNjYWxDYXNlKCl9fU1vZHVsZSBleHRlbmRzIFNlcmludXNNb2R1bGV7fQ==',
        'type': 'text'
      }
    ],
    'name': 'create_service',
    'version': '0.0.1-dev.3',
    'environment': {'mason': '>=0.1.0-dev <0.1.0'},
    'changelog': {
      'path': 'CHANGELOG.md',
      'data':
          'IyMgMC4wLjEtZGV2LjEKCi0gSW5pdGlhbCB2ZXJzaW9uLgo=',
      'type': 'text'
    },
    'description': 'A Serinus template for creating a service',
    'license': {
      'path': 'LICENSE',
      'data': 'TUlUIExpY2Vuc2UKCkNvcHlyaWdodCAoYykgMjAyMyBGcmFuY2VzY28gVmFsbG9uZQoKUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGEgY29weQpvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSAiU29mdHdhcmUiKSwgdG8gZGVhbAppbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzCnRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCwgZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwKY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdCBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzCmZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6CgpUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZCBpbiBhbGwKY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS4KClRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCAiQVMgSVMiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTIE9SCklNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZLApGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUKQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSwgREFNQUdFUyBPUiBPVEhFUgpMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLApPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEUgVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRQpTT0ZUV0FSRS4K',
      'type': 'text'
    },
    'vars': {
      'name': {
        'type': 'string',
        'description': 'Your resource name',
        'default': 'example',
        'prompt': 'What is your resource name?'
      },
      'path': {
        'type': 'string',
        'description': 'Your resource path',
        'default': 'example',
        'prompt': 'What is your resource path?'
      }
    }
  });
} 
