---
description: Extract a specific page from a PDF and convert it to PNG
keywords: [pdf, image, convert, debug]
---

Extract page {{page_number}} from {{pdf_file}} and save as PNG.

Use pdftoppm to convert the specified page to a high-resolution PNG image:

```bash
pdftoppm -png -f {{page_number}} -l {{page_number}} -r 300 "{{pdf_file}}" "{{pdf_file}}_page_{{page_number}}"
```

The output file will be named: `{{pdf_file}}_page_{{page_number}}-1.png`

After conversion, display the image using the Read tool so it can be inspected.
