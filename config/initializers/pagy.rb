# config/initializers/pagy.rb

# Lade die Bootstrap-Integration
require "pagy/extras/bootstrap"

# Setze Bootstrap als Standard-UI für die pagy-Navigationshelfer
Pagy::DEFAULT[:ui] = :bootstrap