# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
pin "dompurify" # @3.4.15
pin "marked" # @18.0.12
pin "highlight.js", to: "https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11/es/highlight.min.js"
