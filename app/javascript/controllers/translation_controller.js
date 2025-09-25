// app/javascript/controllers/translation_controller.js
import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "output", "sourceLanguage", "sourceLabel", "sourceBadge", "inputStatus", "translationStatus", "saveBtn"]

    connect() {
        this.debounceTimer = null;
        this.currentTranslation = null; // Store current translation data
        this.updateSourceLanguageDisplay();
        this.setupClearButton();
        this.setupSaveButton();
    }

    inputTargetConnected() {
        this.inputTarget.addEventListener('input', this.handleInput.bind(this));
    }

    sourceLanguageTargetConnected() {
        this.sourceLanguageTarget.addEventListener('change', this.handleLanguageChange.bind(this));
    }

    setupClearButton() {
        const clearBtn = document.getElementById('clear-btn');
        if (clearBtn) {
            clearBtn.addEventListener('click', this.clearAll.bind(this));
        }
    }

    setupSaveButton() {
        if (this.saveBtnTarget) {
            this.saveBtnTarget.addEventListener('click', this.saveVocabulary.bind(this));
        }
    }

    handleInput() {
        clearTimeout(this.debounceTimer);

        const text = this.inputTarget.value.trim();

        if (text.length === 0) {
            this.clearOutput();
            return;
        }

        this.inputStatusTarget.textContent = 'Eingabe erkannt...';

        // Debounce the translation request
        this.debounceTimer = setTimeout(() => {
            this.translateText(text);
        }, 500);
    }

    handleLanguageChange() {
        this.updateSourceLanguageDisplay();

        // Re-translate if there's text
        const text = this.inputTarget.value.trim();
        if (text.length > 0) {
            this.translateText(text);
        }
    }

    updateSourceLanguageDisplay() {
        const selectedValue = this.sourceLanguageTarget.value;
        const selectedOption = this.sourceLanguageTarget.options[this.sourceLanguageTarget.selectedIndex];

        if (selectedValue === '') {
            this.sourceLabelTarget.textContent = 'Quelltext';
            this.sourceBadgeTarget.textContent = 'AUTO';
            this.sourceBadgeTarget.className = 'badge bg-light text-dark';
        } else {
            const languageName = selectedOption.textContent.split(' (')[0];
            const languageCode = selectedValue.toUpperCase();

            this.sourceLabelTarget.textContent = languageName;
            this.sourceBadgeTarget.textContent = languageCode;
            this.sourceBadgeTarget.className = 'badge bg-info text-white';
        }
    }

    async translateText(text) {
        try {
            this.translationStatusTarget.textContent = 'Übersetze...';
            this.outputTarget.innerHTML = '<div class="text-muted"><i class="spinner-border spinner-border-sm me-2"></i>Übersetze...</div>';

            const sourceLanguage = this.sourceLanguageTarget.value;

            const response = await fetch('/translate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
                },
                body: JSON.stringify({
                    text: text,
                    source_lang: sourceLanguage || null
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();

            if (data.error) {
                throw new Error(data.error);
            }

            // Store current translation data for saving
            this.currentTranslation = {
                source_text: text,
                target_text: data.translated_text,
                source_language: (data.source_language || data.detected_language).toLowerCase()
            };

            this.displayTranslation(data);
            this.inputStatusTarget.textContent = `${text.length} Zeichen eingegeben`;

            // Update detected language if auto-detection was used
            if (!sourceLanguage && data.detected_language) {
                this.updateDetectedLanguage(data.detected_language);
            }

        } catch (error) {
            console.error('Translation error:', error);
            this.outputTarget.innerHTML = `
        <div class="text-center text-danger">
          <i class="bi bi-exclamation-triangle" style="font-size: 2rem;"></i>
          <p class="mb-0 mt-2">Übersetzung fehlgeschlagen</p>
          <small>${error.message}</small>
        </div>
      `;
            this.translationStatusTarget.textContent = 'Fehler bei der Übersetzung';
            this.currentTranslation = null;
        }
    }

    displayTranslation(data) {
        this.outputTarget.innerHTML = `
      <div class="translation-text">
        <p class="mb-0">${data.translated_text}</p>
      </div>
    `;

        let statusText = 'Übersetzung abgeschlossen';
        if (data.detected_language && !this.sourceLanguageTarget.value) {
            statusText += ` (${data.detected_language} erkannt)`;
        }

        this.translationStatusTarget.textContent = statusText;
        this.saveBtnTarget.disabled = false;
    }

    async saveVocabulary() {
        if (!this.currentTranslation) {
            alert('Keine Übersetzung zum Speichern verfügbar');
            return;
        }

        // Disable save button during request
        this.saveBtnTarget.disabled = true;
        this.saveBtnTarget.innerHTML = '<i class="spinner-border spinner-border-sm me-1"></i>Speichere...';

        try {
            const response = await fetch('/vocabularies', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
                },
                body: JSON.stringify(this.currentTranslation)
            });

            const data = await response.json();

            if (data.success) {
                // Show success message
                this.showMessage(data.message, 'success');

                // Keep button disabled after successful save
                this.saveBtnTarget.innerHTML = '<i class="bi bi-check me-1"></i>Gespeichert';
                this.saveBtnTarget.className = 'btn btn-outline-success';
            } else {
                // Show error message
                this.showMessage(data.message || data.error, 'warning');

                // Re-enable button
                this.saveBtnTarget.disabled = false;
                this.saveBtnTarget.innerHTML = '<i class="bi bi-floppy me-1"></i>Vokabel speichern';
            }
        } catch (error) {
            console.error('Save error:', error);
            this.showMessage('Fehler beim Speichern der Vokabel', 'danger');

            // Re-enable button
            this.saveBtnTarget.disabled = false;
            this.saveBtnTarget.innerHTML = '<i class="bi bi-floppy me-1"></i>Vokabel speichern';
        }
    }

    showMessage(message, type) {
        // Create and show a temporary alert message
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show mt-3`;
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;

        // Insert after the card
        const card = document.querySelector('.card');
        card.parentNode.insertBefore(alertDiv, card.nextSibling);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 5000);
    }

    updateDetectedLanguage(detectedLanguage) {
        if (!this.sourceLanguageTarget.value) {
            // Update badge to show detected language
            this.sourceBadgeTarget.textContent = detectedLanguage;
            this.sourceBadgeTarget.className = 'badge bg-success text-white';
        }
    }

    clearOutput() {
        this.outputTarget.innerHTML = `
      <div class="placeholder-content text-center text-muted">
        <i class="bi bi-translate" style="font-size: 2rem;"></i>
        <p class="mb-0 mt-2">Die Übersetzung wird hier erscheinen...</p>
      </div>
    `;
        this.inputStatusTarget.textContent = '';
        this.translationStatusTarget.textContent = '';
        this.saveBtnTarget.disabled = true;
        this.saveBtnTarget.innerHTML = '<i class="bi bi-floppy me-1"></i>Vokabel speichern';
        this.saveBtnTarget.className = 'btn btn-success';
        this.currentTranslation = null;

        // Reset badge if auto-detection
        if (!this.sourceLanguageTarget.value) {
            this.sourceBadgeTarget.textContent = 'AUTO';
            this.sourceBadgeTarget.className = 'badge bg-light text-dark';
        }
    }

    clearAll() {
        this.inputTarget.value = '';
        this.clearOutput();
        this.inputTarget.focus();
    }
}
