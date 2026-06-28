import os
import re

files_to_fix = [
    r"lib\features\sales_pos\pos_screen.dart",
    r"lib\features\inventory\inventory_screen.dart",
    r"lib\features\customers\customers_screen.dart",
    r"lib\features\purchases\purchases_screen.dart",
    r"lib\features\orders\admin_orders_screen.dart"
]

for file_path in files_to_fix:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Inject resizeToAvoidBottomInset: false after Scaffold(
        if 'resizeToAvoidBottomInset: false,' not in content:
            content = re.sub(r'(Scaffold\(\s*)', r'\1resizeToAvoidBottomInset: false,\n      ', content, count=1)
            
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {file_path}")
    except Exception as e:
        print(f"Error in {file_path}: {e}")
