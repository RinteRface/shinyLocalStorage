library(shiny)
library(waiter)

ui <- fluidPage(
  useWaiter(),
  waiterOnBusy(),
  tags$script(src = "storage.js"),
  numericInput("number1", "Number 1", NULL),
  numericInput("number2", "Number 2", NULL),
  verbatimTextOutput("value"),
  hr(),
  h6("localStorage content:"),
  verbatimTextOutput("cached_vals")
)

server <- function(input, output, session) {
  val <- eventReactive({
    req(input$number1, input$number2)
    c(input$number1, input$number2, input_initialised())
  }, {
    # Inputs must have value before this can run
    req(input_initialised())
    # Don't trigger fake computation if value is stored in
    # browser localStorage
    res <- input$number1 + input$number2
    # A new value of input$caption must trigger a recalculation
    if (!is.null(input$storage$val) && res == input$storage$val) {
      input$storage$val
    } else {
      # Do something with res ...
      Sys.sleep(10)
      res
    }
  })
  
  input_initialised <- reactiveVal(FALSE)
  
  # To init inputs: must run once and also when storage
  # is NULL
  observeEvent(input$storage, {
    # Give numeric input some default value when no storage
    if (is.null(input$storage)) {
      updateNumericInput(inputId = "number1", value = 1)
      updateNumericInput(inputId = "number2", value = 2)
      print("1) Giving inputs default values ...")
    } else {
      # Take values from the storage
      updateNumericInput(inputId = "number1", value = input$storage$number1)
      updateNumericInput(inputId = "number2", value = input$storage$number2)
      print("1) Retrieving input values from the storage ...")
    }
    input_initialised(TRUE)
  }, ignoreNULL = FALSE, once = TRUE)
  
  # Also need to cache inputs that gave the result
  observeEvent({
    req(input$number1)
  }, {
    if (is.null(input$storage) || input$number1 != input$storage[["number1"]]) {
      session$sendCustomMessage(
        "update-storage", 
        list(
          id = "number1",
          value = input$number1
        )
      ) 
      print(sprintf("2) Caching input$%s", "number1")) 
    }
  })
  
  observeEvent({
    req(input$number2)
  }, {
    if (is.null(input$storage) || input$number2 != input$storage[["number2"]]) {
      session$sendCustomMessage(
        "update-storage", 
        list(
          id = "number2",
          value = input$number2
        )
      ) 
      print(sprintf("2) Caching input$%s", "number2")) 
    }
  })
  
  # Update localStorage to cache the new reactive result
  observeEvent(val(), {
    if (is.null(input$storage$val) || val() != input$storage[["val"]]) {
      session$sendCustomMessage(
        "update-storage", 
        list(
          id = "val",
          value = val()
        )
      ) 
      print("Caching `val`")
    }
  })
  
  output$value <- renderText({ 
    sprintf(
      "%s + %s = %s",
      input$number1,
      input$number2,
      val()
    ) 
  })
  
  output$cached_vals <- renderPrint(input$storage)
}

shinyApp(ui, server)
