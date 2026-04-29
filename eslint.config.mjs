import js from "@eslint/js";

export default [
    {
        ignores: ["node_modules/**", "public/**", "logs/**"]
    },
    js.configs.recommended,
    {
        rules: {
            "no-unused-vars": "warn",
            "no-undef": "off", // disable because we run node environments
            "no-useless-assignment": "off"
        }
    }
];
