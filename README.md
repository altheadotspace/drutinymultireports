# Drutiny Reporting Script

## Versions

### Version 1.20230515

- **Automated multi-report generation**: Effortlessly create numerous Drutiny reports with a single command.
- **Customizable configuration**: Tailor report generation to your specific needs, such as:
  - Selecting desired Drutiny scanners
  - Adjusting report output formats
  - Specifying output directories
- **Enhanced efficiency**: Generate multiple reports simultaneously, optimizing your workflow.
- **Comprehensive coverage**: Gain a thorough understanding of your application's security posture from diverse perspectives.

### Version 2.20250515

This version introduces support for command-line options, allowing users to specify configurations directly from the command line, rather than being solely reliant on interactive prompts. This enhancement provides greater flexibility and enables smoother automation and integration into larger workflows.

## Overview

This script automates the process of running Drutiny reports for various analyses of your Drupal sites. It is compatible with Bash 3.2 and above.

## Requirements

To run this script, ensure the following software and conditions are met:

- **Bash**: Version 3.2 or higher.
- **Drutiny**: Installed and accessible either as `drutinycs` or `drutiny`. The script checks both command names to determine which one is available on the system and uses it for executing Drutiny operations.
- **Python 3**: Required for generating summary JSON files if `createjson` is enabled.
- **Python Script**: `combine_summaries.py` should be located in the same directory as `multi_reporst.sh`.
- **Permissions**: Appropriate permissions to create directories and files within the specified directories.

## Initialization Steps

The script begins by setting up an SSH environment and clearing the Drutiny cache:

- **SSH Agent Initialization**: The script starts an SSH agent and adds keys from the macOS Keychain for secure access operations.

  ```
    eval $(ssh-agent)
    ssh-add --apple-load-keychain
  ```   

- **Drutiny Cache Clearing**: It clears the Drutiny cache, including source cache, ensuring that reports are generated with the freshest data.

  ```
    drutinycs cache:clear --include-source-cache
  ```  

## How the Script Generates Reports

### Directory Structure

After executing the script, it generates reports within a structured directory hierarchy based on the site name and the current date:

- **`<sitename>/`**: A directory named after the site identifier.
  - **`<year>/`**: Subdirectory for the year when the report is generated.
    - **`<week>_<sitename><env>-<timestamp>/`**: A unique directory for each report run, incorporating the current week number, site name, environment, and precise timestamp.

### Files Generated

Within each reporting directory:

- **HTML Reports**: Each type of Drutiny profile run (`load_analysis`, `health_analysis`, `traffic_analysis`, `app_analysis`) results in an HTML formatted report.

- **Site Review Reports**: When the site review option is enabled, detailed HTML reports are generated for each domain under review. These contain insights into the configuration and state of each site, focusing on aspects like security, performance, and best practice compliance.

- **CSV Reports**: If the site reviews are set to output in CSV format (using the `--sitereview-format=2` or `--sitereview-format=3` options), a CSV file is generated. This CSV is useful for:
  - Quickly scanning and identifying key metrics across multiple sites.
  - Integrating and analyzing data in spreadsheet software like Excel or Google Sheets.
  - Supporting audit processes by providing a straightforward, tabular view of site configurations and statuses.

- **JSON Reports (Optional)**: If the `--createjson=1` option is used, JSON versions of the reports are also created.
- **Summary Files**: If `combine_summaries.py` is executed, summary JSONs are generated to provide an AI-friendly overview of the results.


Here you will find both HTML and, optionally, JSON report files corresponding to various analyses requested.

## Warning

Running site reviews for all sites (`--domain-selection=1`) can impact the performance of your database as it involves querying the Drupal configuration extensively. To mitigate potential performance issues:

- Consider running the site review on a limited number of sites using the `--sitereview-limit` option.
- Alternatively, use a text file with a list of domains for customized domain selection by setting `--domain-selection=4` and providing the `--domain-list-path`.

## JSON Functionality (Beta)

The JSON functionality, enabled by setting `--createjson=1`, is currently in beta and may not work as expected under all circumstances. Please report any issues to the development team for further improvement.

## Example

Here's an example of running the script to analyze a site:

```
./your-script.sh --sitename=example --env=prod --drupal=1 --sitereview=1 --domain-selection=1 --otherreports=1 --loadanalysis=1 --createjson=1
```

This command will run site reviews and other analyses on the specified site and environment, create JSON reports, and use all domains for site review.

Notes
Ensure your terminal can handle ANSI escape sequences to see colored output correctly.
Ensure that the Python script for JSON summary is executable and accessible at the specified path.
Copy code

This complete version of the README includes all sections and details, ensuring users have all the necessary information to understand and use the script effectively.
