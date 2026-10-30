PLANTUML_JAR = tools/plantuml.jar
DIAGRAMS_DIR = docs/diagrams
OUTPUT_DIR = docs/diagrams/rendered

.PHONY: check-diagrams render-diagrams

check-diagrams:
	@echo "Checking PlantUML syntax..."
	@java -jar $(PLANTUML_JAR) -checkonly $(DIAGRAMS_DIR)/**/*.puml
	@echo "All diagrams are valid."

render-diagrams: check-diagrams
	@echo "Generating SVG images..."
	@mkdir -p $(OUTPUT_DIR)
	@java -jar $(PLANTUML_JAR) -tsvg -o $(OUTPUT_DIR) $(DIAGRAMS_DIR)/**/*.puml
	@echo "SVG images saved to $(OUTPUT_DIR)"