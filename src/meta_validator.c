name: Meta-Validator V3 CI

on:
  push:
    paths:
      - 'src/meta_validator.c'
  pull_request:
    paths:
      - 'src/meta_validator.c'
  workflow_dispatch:  # permet execution manuelle

jobs:
  meta-validator:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Compiler Meta-Validator
        run: |
          cd src
          gcc -Wall -Wextra -O2 -o meta_validator meta_validator.c -lm
      
      - name: Executer Meta-Validator
        run: |
          cd src
          ./meta_validator
      
      - name: Verifier code retour
        run: |
          cd src
          ./meta_validator
          test $? -eq 0
      
      - name: Upload rapport JSON
        uses: actions/upload-artifact@v4
        with:
          name: meta-audit-report
          path: src/meta_audit_report.json
