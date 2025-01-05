function formatDate(timestamp) {
    return new Date(timestamp * 1000).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

async function updateLeaderboard() {
    const tbody = document.getElementById('leaderboardBody');
    tbody.innerHTML = '<tr><td colspan="8" class="text-center p-4">Loading...</td></tr>';
    
    try {
        const response = await fetch('https://kv.mpw.sh/api/scores');
        const data = await response.json();
        
        const validScores = data
            .filter(entry => {
                const sha256 = text => CryptoJS.SHA256(text).toString(CryptoJS.enc.Hex);
                const expectedHash = sha256(
                    entry.value.timestamp + ":" + entry.value.score
                );
                return entry.value.hash === expectedHash;
            })
            .sort((a, b) => b.value.score - a.value.score);

        tbody.innerHTML = validScores.map((score, index) => `
            <tr class="hover:bg-neutral-200 dark:hover:bg-neutral-700">
                <td class="p-3">${index + 1}</td>
                <td class="p-3">${score.value.username}</td>
                <td class="p-3">${score.value.score.toLocaleString()}</td>
                <td class="p-3">${score.value.distance.toLocaleString()}</td>
                <td class="p-3 text-game-perfect">${score.value.strafes.perfect}</td>
                <td class="p-3 text-game-early">${score.value.strafes.early}</td>
                <td class="p-3 text-game-late">${score.value.strafes.late}</td>
                <td class="p-3">${formatDate(score.value.timestamp)}</td>
            </tr>
        `).join('');
    } catch (error) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center p-4 text-red-500">Error loading leaderboard</td></tr>';
    }
}

// Tab handling
document.querySelectorAll('.tab-button').forEach(button => {
    button.addEventListener('click', () => {
        // Update the sidebar buttons
        document.querySelectorAll('.tab-button').forEach(btn => {
            btn.classList.remove('active', 'bg-neutral-100', 'dark:bg-neutral-800');
        });
        button.classList.add('active', 'bg-neutral-100', 'dark:bg-neutral-800');

        // Update the content visibility
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.add('hidden');
        });
        const tabId = button.dataset.tab;
        const tabContent = document.getElementById(tabId);
        tabContent.classList.remove('hidden');
        
        // Update leaderboard if selected
        if (tabId === 'leaderboard') {
            updateLeaderboard();
        }
    });
});

// Initial load if starting on leaderboard tab
if (document.querySelector('.tab-button[data-tab="leaderboard"]').classList.contains('active')) {
    updateLeaderboard();
}
