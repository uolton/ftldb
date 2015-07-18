/*
 * Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ftldb.ext;


import freemarker.core.EnvironmentInternalsAccessor;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;

import java.util.List;


/**
 * This class implements an FTL method named {@code template_line} that returns the current line number in a template.
 * No arguments are needed.
 *
 * <p>Method definition: {@code int template_line()}
 *
 * <p>Usage examples in FTL:
 * <pre>
 * {@code
 * current line is ${template_line()}
 * }
 * </pre>
 */
public class TemplateLineMethod implements TemplateMethodModelEx {


    public Object exec(List args) throws TemplateModelException {
        if (args.size() != 0) {
            throw new TemplateModelException("No arguments needed");
        }
        return new Integer(EnvironmentInternalsAccessor.getInstructionStackSnapshot()[0].getBeginLine());
    }


}
