/* Query to find for each day the fraction of Washington covid PCR tests which were positive, 
and the fraction of tests from 02/09/2021 to 03/07/2021 that were administered on that day. */

# Use LAG to find the number of new positive and negative tests each day.
WITH tests AS (  
  SELECT
    date, 
    state,
    negative_tests_viral - LAG(negative_tests_viral) OVER(order by date) AS new_negative_tests,
    positive_tests_viral - LAG(positive_tests_viral) OVER(order by date) AS new_positive_tests,
  FROM
    `bigquery-public-data`.covid19_tracking.state_testing_and_outcomes
  WHERE
    state = "WA"
)
SELECT
  *, 
  # Compute the percentage of positive test results.
  SAFE_DIVIDE(new_positive_tests, new_negative_tests + new_positive_tests) AS daily_percent_positive,
  # Compute the fraction of all test results that came on on this particular day, out of all days in the data.
  (new_negative_tests + new_positive_tests) / SUM(new_positive_tests + new_negative_tests) OVER() AS fraction_of_tests
FROM
  tests
WHERE
  # Ignore days where we don't have data.
  new_negative_tests IS NOT NULL 
  AND new_positive_tests IS NOT NULL
ORDER BY
  date;
