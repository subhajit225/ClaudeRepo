({
    convertBytesToMB: function(bytes) {
        if (bytes < 0) return "0 bytes"; // Handle negative sizes
        
        const units = ['bytes', 'KB', 'MB', 'GB'];
        let i = 0;
        let size = bytes;
        
        while (size >= 1024 && i < units.length - 1) {
            size /= 1024;
            i++;
        }
        
        return size.toFixed(0) + ' ' + units[i]; // Two decimal places
    }
})