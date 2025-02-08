module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "subject-case": [0, "always"], // 한글 허용
    "header-max-length": [2, "always", 100] // 제목 길이 늘리기
  }
};
