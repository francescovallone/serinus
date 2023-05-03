import 'package:mason/mason.dart';

MasonBundle generateModuleTemplate(String type, String name){
  return MasonBundle.fromJson({
    'files': [
      {
        'path': '${name}_$type.dart',
        'data': 'aW1wb3J0ICdwYWNrYWdlOnNlcmludXMvc2VyaW51cy5kYXJ0JzsKCkBNb2R1bGUoCiAgaW1wb3J0czogW10sCiAgY29udHJvbGxlcnM6IFtdLAogIHByb3ZpZGVyczogW10sCikKY2xhc3Mge3tuYW1lLnBhc2NhbENhc2UoKX19IGV4dGVuZHMgU2VyaW51c01vZHVsZXt9',
        'type': 'text'
      },
    ],
    'name': 'create_module',
    'version': '0.0.1-dev.3',
    'environment': {'mason': '>=0.1.0-dev <0.1.0'},
    'changelog': {
      'path': 'CHANGELOG.md',
      'data':
          'IyMgMC4wLjEtZGV2LjEKCi0gSW5pdGlhbCB2ZXJzaW9uLgo=',
      'type': 'text'
    },
    'description': 'A Serinus template for creating a module',
    'license': {
      'path': 'LICENSE',
      'data': 'TUlUIExpY2Vuc2UKCkNvcHlyaWdodCAoYykgMjAyMyBGcmFuY2VzY28gVmFsbG9uZQoKUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGEgY29weQpvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSAiU29mdHdhcmUiKSwgdG8gZGVhbAppbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzCnRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCwgZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwKY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdCBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzCmZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6CgpUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZCBpbiBhbGwKY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS4KClRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCAiQVMgSVMiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTIE9SCklNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZLApGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUKQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSwgREFNQUdFUyBPUiBPVEhFUgpMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLApPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEUgVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRQpTT0ZUV0FSRS4K',
      'type': 'text'
    },
    'vars': {
      'name': {
        'type': 'string',
        'description': 'Your module name',
        'default': 'example',
        'prompt': 'What is your module name?'
      }
    }
  });
} 
