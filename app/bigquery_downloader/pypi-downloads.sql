SELECT
  DAY_ID                                               AS day_id,
  file.project                                         AS project,
  file.version                                         AS project_version,
  REGEXP_EXTRACT(details.python, r"^([^\.]+\.[^\.]+)") AS python_version,
  details.installer.name                               AS installer,
  count(*)                                             AS number_of_downloads
FROM `the-psf.pypi.downloadsDAY_ID`
GROUP BY day_id, project, project_version, python_version, installer;
