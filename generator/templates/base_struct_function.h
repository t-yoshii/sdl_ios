{#- To avoid code duplication was crated this parent file, which contain common part used in:
    "templates/functions/template.h" and "templates/structs/template.h". -#}
{% include 'copyright.txt' %}
{% block imports %}
{%- for import in imports.enum %}
#import "{{import}}.h"
{%- endfor %}
{%- if imports.struct %}
{% endif -%}
{%- for import in imports.struct %}
@class {{import}};
{%- endfor %}
{%- endblock %}

NS_ASSUME_NONNULL_BEGIN
{% include 'description.jinja' %}
@interface {{name}} : {{extends_class}}{{ending}}
{%- block constructors %}
{% for c in constructors %}
/**
 {%- if c.description %}
 {%- for d in c.description %}
 * {{d}}
 {%- endfor %}
 *
 {%- endif %}
 {%- for a in c.all %}
 * @param {{a.variable}} - {{a.constructor_argument}}
 {%- endfor %}
 * @return A {{name}} object
 */
{%- if c.deprecated %}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
{%- endif %}
- (instancetype)initWith{{c.init}};
{%- if c.deprecated %}
#pragma clang diagnostic pop
{%- endif %}
{% endfor -%}
{%- endblock -%}
{%- block methods %}
{%- for param in params %}
{%- include 'description_param.jinja' %}
@property ({{'nullable, ' if not param.mandatory}}{{param.modifier}}, nonatomic) {{param.type_sdl}}{{param.origin}}{{' __deprecated' if param.deprecated and param.deprecated is sameas true }};
{% endfor -%}
{%- endblock %}
@end

NS_ASSUME_NONNULL_END
