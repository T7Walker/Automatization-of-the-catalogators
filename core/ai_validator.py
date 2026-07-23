import re
from typing import List, Dict, Any


class AIValidator:
    """AI-powered text similarity and pattern validation"""

    def __init__(self):
        self._vectorizer = None

    @property
    def vectorizer(self):
        if self._vectorizer is None:
            from sklearn.feature_extraction.text import TfidfVectorizer
            self._vectorizer = TfidfVectorizer()
        return self._vectorizer

    def analyze_step_control(self, step_control_data: Dict) -> Dict[str, Any]:
        """Analyze step control and technical manual"""
        return {
            "code_match": self._compare_codes(
                step_control_data.get('azure', {}).get('code', ''),
                step_control_data.get('file_server', {}).get('code', '')
            ),
            "parametrization_consistent": self._validate_parametrization(
                step_control_data.get('azure', {}).get('parametrization', ''),
                step_control_data.get('file_server', {}).get('parametrization', '')
            ),
            "objects_consistent": self._compare_objects(
                step_control_data.get('azure', {}).get('objects', []),
                step_control_data.get('file_server', {}).get('objects', [])
            ),
            "classes_detected": self._detect_classes(
                step_control_data.get('file_server', {}).get('objects', [])
            ),
            "recommendations": self._analyze_recommendations(
                step_control_data.get('file_server', {}).get('recommendations', '')
            )
        }

    def get_paths(self, step_control_data: Dict) -> Dict[str, str]:
        text = step_control_data.get('file_server', {}).get('content', '')
        return {
            "development": self._extract_development_path(text),
            "testing": self._extract_testing_path(text)
        }

    def check_dependencies(self, work_item_id: str, testing_path: str) -> Dict:
        dependencies = self._extract_dependencies(testing_path)
        return {
            "has_dependencies": len(dependencies) > 0,
            "dependencies": dependencies,
            "recommendation": self._generate_recommendation(dependencies)
        }

    def analyze_changes(self, work_item_id: str) -> Dict:
        return {
            "modified_files": self._detect_modified_files(work_item_id),
            "impact": self._calculate_impact(work_item_id),
            "development_path": self._get_current_development_path(work_item_id),
            "testing_path": self._get_current_testing_path(work_item_id)
        }

    def _compare_codes(self, code_azure: str, code_file_server: str) -> bool:
        if not code_azure or not code_file_server:
            return code_azure == code_file_server
        try:
            from sklearn.metrics.pairwise import cosine_similarity
            similarity = cosine_similarity(
                self.vectorizer.fit_transform([code_azure, code_file_server])
            )[0][1]
            return similarity > 0.9
        except Exception:
            return code_azure == code_file_server

    def _validate_parametrization(self, param_azure: str, param_file_server: str) -> bool:
        return param_azure == param_file_server

    def _compare_objects(self, objects_azure: List[str], objects_file_server: List[str]) -> bool:
        if not objects_azure and not objects_file_server:
            return True
        if not objects_azure or not objects_file_server:
            return False
        matches = 0
        for obj_azure in objects_azure:
            for obj_file in objects_file_server:
                if self._calculate_text_similarity(obj_azure, obj_file) > 0.8:
                    matches += 1
                    break
        return matches == len(objects_azure)

    def _detect_classes(self, objects: List[str]) -> List[str]:
        return [obj for obj in objects if '.class' in obj.lower()]

    def _analyze_recommendations(self, recommendations: str) -> List[str]:
        dependencies = []
        patterns = [
            r"support (\w+) must be applied",
            r"depends on support (\w+)",
            r"requires support (\w+)"
        ]
        for pattern in patterns:
            matches = re.findall(pattern, recommendations, re.IGNORECASE)
            dependencies.extend(matches)
        return dependencies

    def _calculate_text_similarity(self, text1: str, text2: str) -> float:
        if not text1 or not text2:
            return 0.0
        try:
            from sklearn.metrics.pairwise import cosine_similarity
            vector = self.vectorizer.fit_transform([text1, text2])
            return cosine_similarity(vector[0:1], vector[1:2])[0][0]
        except Exception:
            return 0.0

    def _extract_development_path(self, text: str) -> str:
        return ""

    def _extract_testing_path(self, text: str) -> str:
        return ""

    def _extract_dependencies(self, testing_path: str) -> List[str]:
        return []

    def _generate_recommendation(self, dependencies: List[str]) -> str:
        if not dependencies:
            return "No dependencies detected"
        return f"Pending dependencies detected: {', '.join(dependencies)}"

    def _detect_modified_files(self, work_item_id: str) -> List[str]:
        return []

    def _calculate_impact(self, work_item_id: str) -> str:
        return "LOW"

    def _get_current_development_path(self, work_item_id: str) -> str:
        return ""

    def _get_current_testing_path(self, work_item_id: str) -> str:
        return ""