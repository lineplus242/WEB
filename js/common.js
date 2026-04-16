// Backspace 키로 브라우저 뒤로가기 방지
document.addEventListener('keydown', function(e) {
    if (e.key !== 'Backspace') return;

    const el = document.activeElement;
    const tag = el ? el.tagName : '';
    const type = (el && el.type) ? el.type.toLowerCase() : '';

    // 편집 가능한 필드인 경우 → 정상 동작 허용
    const editableTags = ['TEXTAREA'];
    const editableInputTypes = ['text', 'password', 'number', 'email', 'tel', 'url', 'search', 'date', 'time', 'datetime-local', 'month', 'week'];

    if (editableTags.includes(tag)) return;
    if (tag === 'INPUT' && editableInputTypes.includes(type)) return;
    if (el && el.isContentEditable) return;

    // 그 외 모든 곳에서 Backspace → 뒤로가기 차단
    e.preventDefault();
});
