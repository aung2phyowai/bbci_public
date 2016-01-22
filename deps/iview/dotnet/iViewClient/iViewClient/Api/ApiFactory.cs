using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace iViewClient.Api
{
    public static class ApiFactory
    {
        public static IDllWrapper Create()
        {
            if (IntPtr.Size == 8)
            {
                return new DllWrapper_x64();
            }
            else
            {
                return new DllWrapper_x86();
            }
        }
    }
}
