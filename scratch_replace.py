import os
import glob

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if "import 'package:pdf/widgets.dart' as pw;" not in content:
        return

    if "import '../utils/pdf_text.dart';" not in content:
        # Add import
        content = content.replace("import 'package:pdf/widgets.dart' as pw;", "import 'package:pdf/widgets.dart' as pw;\nimport '../utils/pdf_text.dart';")

    content = content.replace('pw.Text(', 'buildPdfText(')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for filepath in glob.glob('lib/core/services/pdf_*_service.dart'):
    process_file(filepath)
    print(f"Processed {filepath}")
