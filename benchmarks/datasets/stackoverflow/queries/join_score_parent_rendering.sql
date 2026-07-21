-- Shape: Hierarchical Cross-Table Scoring (Rendering the Parent, 1:N)
-- Description: The application UI renders a list of "Posts". A Post's ranking is a combination 
-- of its own text match AND the text matches of its child Comments. 
-- Using a CTE for the child table search avoids the row-explosion of a flat LEFT JOIN.

-- Query Info (statistics from 100k dataset; larger datasets may have different values):
-- - 'error' selectivity on stackoverflow_posts.title: ~1%
-- - 'error' selectivity on comments.text: ~1%

-- Postgres default plan (custom scan off)
SET work_mem TO '4GB'; SET paradedb.enable_join_custom_scan TO off; WITH comment_hits AS (
    SELECT post_id, SUM(pdb.score(id)) AS comment_score
    FROM comments
    WHERE text ||| 'error'
    GROUP BY post_id
)
SELECT 
    p.id, 
    p.title,
    COALESCE(pdb.score(p.id), 0.0) + COALESCE(ch.comment_score, 0.0) AS total_score
FROM stackoverflow_posts p
LEFT JOIN comment_hits ch ON p.id = ch.post_id
WHERE p.title ||| 'error' OR ch.post_id IS NOT NULL
ORDER BY total_score DESC
LIMIT 10;

-- TODO(https://github.com/paradedb/paradedb/issues/4778): JoinScan cannot absorb joins where one side is an aggregated subquery (CTE).
-- TODO(https://github.com/paradedb/paradedb/issues/4887): LEFT OUTER JOIN is not yet supported by JoinCustomScan.
-- Custom scan enabled
SET work_mem TO '4GB'; SET paradedb.enable_join_custom_scan TO on; WITH comment_hits AS (
    SELECT post_id, SUM(pdb.score(id)) AS comment_score
    FROM comments
    WHERE text ||| 'error'
    GROUP BY post_id
)
SELECT 
    p.id, 
    p.title,
    COALESCE(pdb.score(p.id), 0.0) + COALESCE(ch.comment_score, 0.0) AS total_score
FROM stackoverflow_posts p
LEFT JOIN comment_hits ch ON p.id = ch.post_id
WHERE p.title ||| 'error' OR ch.post_id IS NOT NULL
ORDER BY total_score DESC
LIMIT 10;
