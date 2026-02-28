import requests
import json

# Test the ML model with an image upload
print("📤 Testing ML model with clinical laboratory report image...\n")

url = "http://localhost:8000/upload-image"

# Note: You'll need to save the image first, then run this
# For now, let's check if we can use the sample we have
try:
    # Try to use any image file we can find
    import os
    
    # Check for common image files
    image_files = [f for f in os.listdir('.') if f.endswith(('.png', '.jpg', '.jpeg'))]
    
    if not image_files:
        print("❌ No image files found in current directory")
        print("Please save the image as 'test_lab_report.jpg' and run again")
        exit(1)
    
    test_image = image_files[0]
    print(f"Using image file: {test_image}\n")
    
    files = {'file': open(test_image, 'rb')}
    
    print("🔄 Sending request to backend (this may take 2-3 minutes for OCR)...")
    response = requests.post(url, files=files, timeout=300)
    
    print(f"\nStatus Code: {response.status_code}\n")
    
    if response.status_code == 200:
        result = response.json()
        print("=" * 70)
        print("✅ ML MODEL OUTPUT:")
        print("=" * 70)
        print(json.dumps(result, indent=2))
        
        print("\n" + "=" * 70)
        print("📊 DETAILED ANALYSIS:")
        print("=" * 70)
        print(f"\n🏥 Report Type: {result.get('report_type', 'N/A')}")
        print(f"\n⚠️  Abnormal Values Found: {len(result.get('abnormal', []))}")
        if result.get('abnormal'):
            for abnormal in result['abnormal']:
                print(f"    • {abnormal}")
        else:
            print("    • None - All values within normal range")
        
        print(f"\n📈 Severity: {result.get('severity', 'N/A')}")
        
        print(f"\n📝 Summary:")
        summary = result.get('summary', 'N/A')
        # Wrap text for better readability
        import textwrap
        wrapped = textwrap.fill(summary, width=65)
        for line in wrapped.split('\n'):
            print(f"    {line}")
        
        print(f"\n📊 Total Words Extracted: {result.get('total_words', 'N/A')}")
        print(f"\n⏰ Timestamp: {result.get('timestamp', 'N/A')}")
        print("=" * 70)
        
    else:
        print(f"❌ Error {response.status_code}: {response.text}")
        
except requests.exceptions.Timeout:
    print("❌ Request timed out. OCR processing may be taking too long.")
    print("Check the backend terminal for processing status.")
except Exception as e:
    print(f"❌ Exception: {str(e)}")
