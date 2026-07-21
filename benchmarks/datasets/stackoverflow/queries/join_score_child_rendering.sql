-- Shape: Hierarchical Cross-Table Scoring (Rendering the Child, N:1)
-- Description: The application UI renders a list of "Comments" (the bottom of the hierarchy).
-- A comment's ranking is boosted if its parent Post also matches the search.
-- Because every comment has exactly one parent Post, a flat LEFT OUTER JOIN is used without row explosion.

-- Query Info (statistics from 100k dataset; larger datasets may have different values):
-- - 'error' selectivity on stackoverflow_posts.title: ~1%
-- - 'error' selectivity on comments.text: ~1%

-- Postgres default plan (custom scan off)
SET work_mem TO '4GB'; SET paradedb.enable_join_custom_scan TO off; SELECT 
    c.id AS comment_id,
    c.text,
    COALESCE(pdb.score(c.id), 0.0) + COALESCE(pdb.score(p.id), 0.0) AS total_score
FROM comments c
LEFT OUTER JOIN stackoverflow_posts p ON c.post_id = p.id
WHERE c.text ||| 'error' OR p.title ||| 'error'
ORDER BY total_score DESC
LIMIT 10;

-- TODO(https://github.com/paradedb/paradedb/issues/4887): LEFT OUTER JOIN is not yet supported by JoinCustomScan.
-- Custom scan enabled
SET work_mem TO '4GB'; SET paradedb.enable_join_custom_scan TO on; SELECT 
    c.id AS comment_id,
    c.text,
    COALESCE(pdb.score(c.id), 0.0) + COALESCE(pdb.score(p.id), 0.0) AS total_score
FROM comments c
LEFT OUTER JOIN stackoverflow_posts p ON c.post_id = p.id
WHERE c.text ||| 'error' OR p.title ||| 'error'
ORDER BY total_score DESC
LIMIT 10;
