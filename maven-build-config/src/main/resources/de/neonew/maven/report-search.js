// Shared by the standalone HTML reports; embedded at report generation time.
function createReportTextMatcher(query, { substring = false } = {}) {
  query = query.trim();
  if (!query) return () => true;

  if (query.includes('*')) {
    const pattern = new RegExp(query.split('*')
      .map(part => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
      .join('.*'), 'i');
    return text => pattern.test(text);
  }

  const lowerQuery = query.toLowerCase();
  // Mixed abbreviations such as MFeaT mean M + Fea + T.
  const parts = (query.match(/\p{Lu}\p{Ll}*|[\p{Ll}\p{N}]+/gu) || [query])
    .map(part => part.toLowerCase());
  const splitWords = value => value
    .replace(/([\p{Ll}\p{N}])(\p{Lu})/gu, '$1 $2')
    .replace(/(\p{Lu})(\p{Lu}\p{Ll})/gu, '$1 $2')
    .split(' ').map(word => word.toLowerCase());

  return text => {
    if (substring && text.toLowerCase().includes(lowerQuery)) return true;

    return text.split(/[^\p{L}\p{N}]+/u).some(word => {
      if (parts.length === 1 && word.toLowerCase().startsWith(parts[0])) return true;
      const words = splitWords(word);
      let next = 0;
      for (const part of parts) {
        while (next < words.length && !words[next].startsWith(part)) next++;
        if (next === words.length) return false;
        next++;
      }
      return true;
    });
  };
}
