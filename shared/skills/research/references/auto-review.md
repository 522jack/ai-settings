# Auto-review modes

Выбирайте `business-analyst`, когда рекомендация существенно зависит от what-to-build/MVP/scope/user trade-off/SLA/cost/business risk. Чисто техническая тема → `tech-sanity` без дополнительного агента. При косвенном product impact по умолчанию tech-sanity.

Business-analyst получает полный синтез и constraints, независимо проверяет полноту альтернатив, technical/product risks, практическую реализуемость, evidence и отсутствие user questions в Known Unknowns. Issues: critical/major/minor. Не получает рассуждений, оправдывающих предпочитаемый ответ.

Tech-sanity: ≥2 viable options либо причины единственного; risks per option с severity; recommendation из конкретных результатов; существенные claims имеют source. Исправьте пробел до сохранения.

Minor → правка текста. Major/critical, разрешимая исследованием → повторить только relevant direction, затем affected review. Нужное product/user решение → чат до итогового отчёта. Внешний неизвестный факт → Known Unknowns с владельцем/условием закрытия; не выдумывать. Повторное review неизменного синтеза не даёт нового сигнала; persistent genuine block после 3 содержательных попыток → evidence+escalation, без бесконечных loops.
