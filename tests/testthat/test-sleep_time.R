context("Test sleep params")
test_that("Test sleep params", {
  testthat::skip_on_cran()
  default.sleep <- geoknife:::gconfig('sleep.time')
  wd <- webprocess()
  expect_equal(wd@sleep.time, default.sleep)
  wd <- webprocess(sleep.time = default.sleep+5)
  expect_false(wd@sleep.time == default.sleep)
})

test_that("Test set sleep global and param", {
  testthat::skip_on_cran()
  default.sleep <- geoknife:::gconfig('sleep.time')
  wd <- webprocess()
  expect_equal(wd@sleep.time, default.sleep)
  geoknife:::gconfig('sleep.time'=default.sleep+5)
  wd <- webprocess()
  expect_equal(wd@sleep.time, default.sleep+5)
  wd <- webprocess(sleep.time = default.sleep)
  expect_equal(wd@sleep.time, default.sleep)
})