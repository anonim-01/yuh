(function () {
    "use strict";

    const decoder = new TextDecoder();

    function base64ToBytes(value) {
        const binaryString = globalThis.atob(value);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i += 1) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes;
    }

    async function decryptPayload(ciphertext, iv, key) {
        const cryptoKey = await globalThis.crypto.subtle.importKey(
            "raw",
            key,
            { name: "AES-GCM" },
            false,
            ["decrypt"],
        );
        const buffer = await globalThis.crypto.subtle.decrypt(
            { name: "AES-GCM", iv },
            cryptoKey,
            ciphertext,
        );
        return decoder.decode(buffer);
    }

    async function hydrate() {
        const root = document.getElementById("encrypted-root");
        if (!root) {
            return;
        }
        try {
            const html = await decryptPayload(
                base64ToBytes(root.dataset.ciphertext || ""),
                base64ToBytes(root.dataset.iv || ""),
                base64ToBytes(root.dataset.key || ""),
            );
            document.body.classList.remove("is-encrypted");
            document.documentElement.classList.add("is-decrypted");
            
            // Modern yöntem: innerHTML kullan ve script'leri manuel çalıştır
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            
            // Script etiketlerini bul ve yeniden oluştur (böylece çalışırlar)
            const scripts = tempDiv.querySelectorAll('script');
            const scriptsToExecute = [];
            
            scripts.forEach(oldScript => {
                const newScript = document.createElement('script');
                
                // Eğer src varsa, onu kullan (jQuery gibi)
                if (oldScript.src) {
                    newScript.src = oldScript.src;
                    newScript.async = false; // Sıralı yükleme için
                } else {
                    // Inline script ise içeriği kopyala
                    newScript.textContent = oldScript.textContent;
                }
                
                // Diğer attribute'ları kopyala
                Array.from(oldScript.attributes).forEach(attr => {
                    if (attr.name !== 'src') {
                        newScript.setAttribute(attr.name, attr.value);
                    }
                });
                
                scriptsToExecute.push(newScript);
                oldScript.parentNode.removeChild(oldScript);
            });
            
            // Body'yi temizle ve yeni içeriği ekle
            document.body.innerHTML = '';
            document.body.appendChild(tempDiv);
            
            // Script'leri sırayla ekle
            scriptsToExecute.forEach(script => {
                document.body.appendChild(script);
            });
            
        } catch (error) {
            console.error("Encrypted payload could not be decrypted", error);
            document.body.classList.add("encryption-error");
            root.hidden = false;
            root.innerHTML = "<p>Şifreli içerik çözümlenemedi. Lütfen sayfayı yenileyin.</p>";
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", hydrate, { once: true });
    } else {
        void hydrate();
    }
})();
