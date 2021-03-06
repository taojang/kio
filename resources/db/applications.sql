-- name: read-applications
SELECT a_id, a_team_id, a_active, a_name, a_subtitle, a_service_url
  FROM zk_data.application;

-- name: search-applications
SELECT a_id,
  a_team_id,
  a_active,
  a_name,
  a_subtitle,
  a_service_url,
  ts_rank_cd(vector, query) AS matched_rank,
  ts_headline('simple', a_description, query) AS matched_description
FROM (SELECT a_id,
        a_team_id,
        a_active,
        a_name,
        a_subtitle,
        a_service_url,
        a_description,
        setweight(to_tsvector('simple', a_name), 'A')
        || setweight(to_tsvector('simple', COALESCE(a_subtitle, '')), 'B')
        || setweight(to_tsvector('simple', COALESCE(a_description, '')), 'C')
          as vector
      FROM zk_data.application) as apps,
  to_tsquery('simple', :searchquery) query
WHERE query @@ vector
ORDER BY matched_rank DESC;

--name: read-application
SELECT a_id, a_team_id, a_active, a_name, a_subtitle, a_description, a_service_url, a_scm_url, a_documentation_url, a_specification_url
  FROM zk_data.application
 WHERE a_id = :id;

-- name: create-or-update-application!
WITH application_update AS (
     UPDATE zk_data.application
        SET a_team_id           = :team_id,
            a_active            = :active,
            a_name              = :name,
            a_subtitle          = :subtitle,
            a_description       = :description,
            a_service_url       = :service_url,
            a_scm_url           = :scm_url,
            a_documentation_url = :documentation_url,
            a_specification_url = :specification_url
      WHERE a_id = :id
  RETURNING *)
INSERT INTO zk_data.application
            (a_id, a_team_id, a_active, a_name, a_subtitle, a_description, a_service_url, a_scm_url, a_documentation_url, a_specification_url)
     SELECT :id, :team_id, :active, :name, :subtitle, :description, :service_url, :scm_url, :documentation_url, :specification_url
      WHERE NOT EXISTS (SELECT * FROM application_update);
