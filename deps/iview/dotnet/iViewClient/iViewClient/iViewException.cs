using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using System.Security.Permissions;

namespace iViewClient
{
    [Serializable]
    public class iViewException : ApplicationException
    {
        public int Code { get; set; }

        public iViewException()
        {
        }

        public iViewException(int code)
            : base(convertToMessage(code))
        {
            Code = code;
        }

        private static string convertToMessage(int code)
        {
            string message;
            switch (code)
            {
                case 104:
                    message = "Could not establish connection. Check if Eye Tracker is running.";
                    break;
                case 105:
                    message = "Could not establish connection. Check the communication Ports.";
                    break;
                case 123:
                    message = "Could not establish connection. Another Process is blocking the communication Ports.";
                    break;
                case 201:
                    message = "Could not establish connection. Check if Eye Tracker is installed and running.";
                    break;
                default:
                    message = "Refer to the iView X SDK Manual for its meaning.";
                    break;
            }
            string formattedMessage = String.Format("Error {0}: {1}", code, message);

            return formattedMessage;
        }

        public iViewException(string message)
            : base(message)
        {
        }

        public iViewException(string message, Exception inner)
            : base(message, inner)
        {
        }

        protected iViewException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
            Code = info.GetInt32("Code");
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            if (info == null)
            {
                throw new ArgumentNullException("info");
            }

            info.AddValue("Code", Code);
            base.GetObjectData(info, context);
        }
    }
}
