test_that(".parse_size_string converts units to bytes", {
  expect_equal(mospiR:::.parse_size_string("2 KB"), 2048)
  expect_equal(mospiR:::.parse_size_string("1.5 mb"), 1.5 * 1024^2)
  expect_true(is.na(mospiR:::.parse_size_string("lots")))
  expect_true(is.na(mospiR:::.parse_size_string(NULL)))
})

test_that(".rows_to_df fills missing keys with NA", {
  df <- mospiR:::.rows_to_df(list(list(id = 1, title = "a"), list(id = 2)))
  expect_equal(nrow(df), 2)
  expect_equal(df$title, c("a", NA))
})
