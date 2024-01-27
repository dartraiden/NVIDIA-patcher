
#
Function Local-TimeStamp-Server {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $Folder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1
       ,
        [Parameter(Mandatory = $false)]
        [string] $BouncyDll = $BouncyDll
    )

    [string] $Tsa1Crt = "$Folder\Gen-TSA1.crt"
    [string] $Tsa2Crt = "$Folder\Gen-TSA2.crt"
    [string] $TsaKey  = "$Folder\Gen-TSA.key"

    [string] $print1 = ''
    [string] $print2 = ''

    [string[]] $iCert = @() # temp var

    [bool] $Online = $false

    $TimeStampServer = @'
// основано на исходнике Jemmy: https://github.com/Jemmy1228/TimeStampResponder-CSharp
using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Globalization;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.Cms;
using Org.BouncyCastle.Cms;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Operators;
using Org.BouncyCastle.Math;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.Tsp;
using Org.BouncyCastle.X509;
using Org.BouncyCastle.X509.Store;
using Attribute = Org.BouncyCastle.Asn1.Cms.Attribute;

namespace TimeStamp
{
    public static class Program
    {
        internal static string isRespond = "";

        public static void GetListenerRespond()
        {
            if (!String.IsNullOrEmpty(isRespond))
            {
                Console.WriteLine(" + Respond: {0}", isRespond);
                isRespond = "";
            }
            else { Console.WriteLine(" - Not Respond"); }
        }

        static TSResponder tsResponderSha1;
        static TSResponder tsResponderSha256;

        static HttpListener listenerSha1;
        static HttpListener listenerSha256;

        public static void StopListener()
        {
            if (tsResponderSha1 != null)
            {
                if (listenerSha1 != null)
                {
                    listenerSha1.Stop();
                    listenerSha1.Close();
                    listenerSha1 = null;
                    tsResponderSha1 = null;
                }
            }

            if (tsResponderSha256 != null)
            {
                if (listenerSha256 != null)
                {
                    listenerSha256.Stop();
                    listenerSha256.Close();
                    listenerSha256 = null;
                    tsResponderSha256 = null;
                }
            }
        }

        static async void StartListenerSha1Async()
        {
			await Task.Run(() =>
			{
				try
				{
                    while (listenerSha1 != null)
                    {
                        HttpListenerContext ctx = listenerSha1.GetContext();
                        ThreadPool.QueueUserWorkItem(new WaitCallback(TaskProc), ctx);
                    }
				}
				catch (Exception) {}
			});
        }

        static async void StartListenerSha256Async()
        {
			await Task.Run(() =>
			{
				try
				{
                    while (listenerSha256 != null)
                    {
                        HttpListenerContext ctx = listenerSha256.GetContext();
                        ThreadPool.QueueUserWorkItem(new WaitCallback(TaskProc), ctx);
                    }
				}
				catch (Exception) {}
			});
        }

        public static void StartResponder(string crt, string privateKey, string hashName, bool silent = false)
        {
            bool sha1 = true;
            string TSAPath = @"/TS-SHA1/";
            hashName = hashName.ToUpper();

            if (string.Equals(hashName, "SHA256"))
            {
                sha1 = false;
                TSAPath = @"/TS-SHA256/";
                if (tsResponderSha256 != null)
                {
                    if (!silent) { Console.WriteLine("TimeStamp server is already running: SHA256"); }
                    return;
                }
            }
            else if (string.Equals(hashName, "SHA1"))
            {
                if (tsResponderSha1 != null)
                {
                    if (!silent) { Console.WriteLine("TimeStamp server is already running: SHA1"); }
                    return;
                }
            }
            else
            {
                Console.WriteLine("error: Only SHA1 or SHA256");
                return;
            }

            try
            {
                if (sha1)
                {
                    tsResponderSha1 = new TSResponder(File.ReadAllBytes(crt), File.ReadAllBytes(privateKey), hashName);
                    listenerSha1    = new HttpListener();
                }
                else
                {
                    tsResponderSha256 = new TSResponder(File.ReadAllBytes(crt), File.ReadAllBytes(privateKey), hashName);
                    listenerSha256    = new HttpListener();
                }
            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("[Local-TimeStamp-Server] Exception: {0}", e);
                Console.WriteLine("[Local-TimeStamp-Server] Please check your cert and key! [{0}]", hashName);
                Console.ForegroundColor = ConsoleColor.Gray;
                Console.WriteLine();
                return;
            }

            try
            {
                if (sha1)
                {
                    listenerSha1.AuthenticationSchemes = AuthenticationSchemes.Anonymous;
                    listenerSha1.Prefixes.Add(@"http://localhost" + TSAPath);
                    listenerSha1.Start();
                }
                else
                {
                    listenerSha256.AuthenticationSchemes = AuthenticationSchemes.Anonymous;
                    listenerSha256.Prefixes.Add(@"http://localhost" + TSAPath);
                    listenerSha256.Start();
                }
            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("[Local-TimeStamp-Server] Exception: {0}", e);
                Console.WriteLine("[Local-TimeStamp-Server] Administrator rights required!");
                Console.ForegroundColor = ConsoleColor.Gray;
                Console.WriteLine();
                return;
            }

            if (sha1)
            {
                if (!silent)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("TimeStamp Server is available at \"http://localhost/TS-SHA1\"   or \"http://localhost/TS-SHA1/yyyy-MM-ddTHH:mm:ss\"");
                    Console.ForegroundColor = ConsoleColor.Gray;
                }

                StartListenerSha1Async();
            }
            else
            {
                if (!silent)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("TimeStamp Server is available at \"http://localhost/TS-SHA256\" or \"http://localhost/TS-SHA256/yyyy-MM-ddTHH:mm:ss\"");
                    Console.ForegroundColor = ConsoleColor.Gray;
                }

                StartListenerSha256Async();
            }
        }

        static void TaskProc(object o)
        {
            HttpListenerContext ctx = (HttpListenerContext)o;
            ctx.Response.StatusCode = 200;

            HttpListenerRequest request = ctx.Request;
            HttpListenerResponse response = ctx.Response;

            bool sha1 = true;
            string log = "", date = "", RawUrl = request.RawUrl, hashAlg = "SHA1", sha1Url = @"/TS-SHA1", sha256Url = @"/TS-SHA256";

            if (RawUrl.StartsWith(sha1Url, StringComparison.InvariantCultureIgnoreCase))
            {
                //date = RawUrl.Replace(@"/TS-SHA1/", "");
                date = RawUrl.Remove(0, sha1Url.Length).Replace(@"/", "");
            }
            else
            {
                //date = RawUrl.Replace(@"/TS-SHA256/", "");
                date = RawUrl.Remove(0, sha256Url.Length).Replace(@"/", "");
                hashAlg = "SHA256";
                sha1 = false;
            }

            if (ctx.Request.HttpMethod != "POST")
            {
                StreamWriter writer = new StreamWriter(response.OutputStream, Encoding.ASCII);
                writer.WriteLine("TSA Server: {0}", hashAlg);
                writer.Close();
                ctx.Response.Close();
                isRespond = "TSA Server: HttpMethod not POST: " + hashAlg;
            }
            else
            {
                DateTime signTime;
                if (!DateTime.TryParseExact(date, "yyyy-MM-dd'T'HH:mm:ss", CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out signTime))
                    signTime = DateTime.UtcNow;

                BinaryReader reader = new BinaryReader(request.InputStream);
                byte[] bRequest = reader.ReadBytes((int)request.ContentLength64);
                byte[] bResponse = null;

                bool RFC;
                if (sha1)
                {
                    bResponse = tsResponderSha1.GenResponse(bRequest, signTime, out RFC);
                }
                else
                {
                    bResponse = tsResponderSha256.GenResponse(bRequest, signTime, out RFC);
                }

                string wrong = "";

                if (RFC)
                {
                    response.ContentType = "application/timestamp-reply";
                    log += "RFC3161     \t";
                    if (sha1) { wrong = " | Need use url: TS-SHA256!"; }
                }
                else
                {
                    response.ContentType = "application/octet-stream";
                    log += "Authenticode\t";
                    if (!sha1) { wrong = " | Need use url: TS-SHA1!"; }
                }

                log += signTime;
                BinaryWriter writer = new BinaryWriter(response.OutputStream);
                writer.Write(bResponse);
                writer.Close();
                ctx.Response.Close();
                isRespond = log + " | " + hashAlg + wrong;
            }
        }
    }

    internal class TSResponder
    {
        X509Certificate x509Cert;
        AsymmetricKeyParameter priKey;
        IX509Store x509Store;
        string hashAlg;

        public TSResponder(byte[] x509Cert, byte[] priKey, string hashAlg)
        {
            this.x509Cert = new X509CertificateParser().ReadCertificate(x509Cert);
            this.priKey = ((AsymmetricCipherKeyPair)(new PemReader(new StreamReader(new MemoryStream(priKey))).ReadObject())).Private;
            this.x509Store = X509StoreFactory.Create("Certificate/Collection",new X509CollectionStoreParameters(new X509CertificateParser().ReadCertificates(x509Cert)));
            this.hashAlg = hashAlg;
        }

        public byte[] GenResponse(byte[] bRequest, DateTime signTime, out bool isRFC, byte[] bSerial = null)
        {
            TimeStampRequest timeStampRequest = null;
            try { timeStampRequest = new TimeStampRequest(bRequest); int v = timeStampRequest.Version; } catch { timeStampRequest = null; }
            ;
            if (timeStampRequest == null)
            {
                isRFC = false;
                return Authenticode(bRequest, signTime);
            }
            else
            {
                isRFC = true;
                if (bSerial == null)
                {
                    bSerial = new byte[16];
                    new Random().NextBytes(bSerial);
                }
                BigInteger biSerial = new BigInteger(1, bSerial);
                return RFC3161(bRequest, signTime, biSerial);
            }
        }

        private byte[] RFC3161(byte[] bRequest,DateTime signTime,BigInteger biSerial)
        {
            TimeStampRequest timeStampRequest = new TimeStampRequest(bRequest);

            Asn1EncodableVector signedAttributes = new Asn1EncodableVector();
            signedAttributes.Add(new Attribute(CmsAttributes.ContentType, new DerSet(new DerObjectIdentifier("1.2.840.113549.1.7.1"))));
            signedAttributes.Add(new Attribute(CmsAttributes.SigningTime, new DerSet(new DerUtcTime(signTime))));
            AttributeTable signedAttributesTable = new AttributeTable(signedAttributes);
            signedAttributesTable.ToAsn1EncodableVector();

            TimeStampTokenGenerator timeStampTokenGenerator = new TimeStampTokenGenerator(priKey, x509Cert, new DefaultDigestAlgorithmIdentifierFinder().find(hashAlg).Algorithm.Id, "1.3.6.1.4.1.13762.3", signedAttributesTable, null);
            timeStampTokenGenerator.SetCertificates(x509Store);
            TimeStampResponseGenerator timeStampResponseGenerator = new TimeStampResponseGenerator(timeStampTokenGenerator, TspAlgorithms.Allowed);
            TimeStampResponse timeStampResponse = timeStampResponseGenerator.Generate(timeStampRequest, biSerial, signTime);
            byte[] result = timeStampResponse.GetEncoded();
            return result;
        }

        private byte[] Authenticode(byte[] bRequest, DateTime signTime)
        {
            string requestString = "";

            for (int i = 0; i < bRequest.Length; i++)
            {
                if (bRequest[i] >= 32)
                    requestString += (char)bRequest[i];
            }

            bRequest = Convert.FromBase64String(requestString);

            Asn1InputStream asn1InputStream = new Asn1InputStream(bRequest);
            Asn1Sequence instance = Asn1Sequence.GetInstance(asn1InputStream.ReadObject());
            Asn1Sequence instance2 = Asn1Sequence.GetInstance(instance[1]);
            Asn1TaggedObject instance3 = Asn1TaggedObject.GetInstance(instance2[1]);
            Asn1OctetString instance4 = Asn1OctetString.GetInstance(instance3.GetObject());
            byte[] octets = instance4.GetOctets();
            asn1InputStream.Close();

            Asn1EncodableVector signedAttributes = new Asn1EncodableVector();
            signedAttributes.Add(new Attribute(CmsAttributes.ContentType, new DerSet(new DerObjectIdentifier("1.2.840.113549.1.7.1"))));
            signedAttributes.Add(new Attribute(CmsAttributes.SigningTime, new DerSet(new DerUtcTime(signTime))));
            AttributeTable signedAttributesTable = new AttributeTable(signedAttributes);
            signedAttributesTable.ToAsn1EncodableVector();
            DefaultSignedAttributeTableGenerator signedAttributeGenerator = new DefaultSignedAttributeTableGenerator(signedAttributesTable);
            SignerInfoGeneratorBuilder signerInfoBuilder = new SignerInfoGeneratorBuilder();
            signerInfoBuilder.WithSignedAttributeGenerator(signedAttributeGenerator);
            ISignatureFactory signatureFactory = new Asn1SignatureFactory(hashAlg+"WithRSA", priKey);

            CmsSignedDataGenerator generator = new CmsSignedDataGenerator();
            generator.AddSignerInfoGenerator(signerInfoBuilder.Build(signatureFactory, x509Cert));
            generator.AddCertificates(x509Store);
            CmsSignedData cmsSignedData = generator.Generate(new CmsProcessableByteArray(octets), true);
            byte[] result = cmsSignedData.ContentInfo.GetEncoded("DER");
            return Encoding.ASCII.GetBytes(Convert.ToBase64String(result).ToArray());
        }
    }
}
'@

    Get-Data-Preset -Menu

    if ( [System.IO.File]::Exists($Tsa1Crt) -and [System.IO.File]::Exists($Tsa2Crt) -and [System.IO.File]::Exists($TsaKey) )
    {
        [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux', '-fingerprint', '-sha1'

        # Cert Tsa1 info
        $iCert = & $openssl x509 -in $Tsa1Crt -text -noout $x509params 2>$null

        $print1 = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})

        if ( -not $print1 )
        {
            Write-Host '  TSA1 server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '○ ' -ForegroundColor DarkYellow -NoNewline
            Write-Host '| Error Gen-TSA1.crt' -ForegroundColor Red

            $PrintTSAGlobal = [PSCustomObject]@{}

            Return
        }

        [string] $SigAlg1 = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value

        if ( -not ( $SigAlg1 -match '^SHA1$' ))
        {
            Write-Host '  TSA1 server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '○ ' -ForegroundColor DarkYellow -NoNewline
            Write-Host '| ' -ForegroundColor DarkGray -NoNewline
            Write-Host 'Gen-TSA1.crt not SHA1' -ForegroundColor Red

            $PrintTSAGlobal = [PSCustomObject]@{}

            Return
        }


        # Cert Tsa2 info
        $iCert = & $openssl x509 -in $Tsa2Crt -text -noout $x509params 2>$null

        $print2 = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})

        if ( -not $print2 )
        {
            Write-Host '  TSA2 server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '○ ' -ForegroundColor DarkYellow -NoNewline
            Write-Host '| Error Gen-TSA2.crt' -ForegroundColor Red

            $PrintTSAGlobal = [PSCustomObject]@{}

            Return
        }

        [string] $SigAlg2 = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value

        if ( -not ( $SigAlg2 -match '^SHA256$' ))
        {
            Write-Host '  TSA2 server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '○ ' -ForegroundColor DarkYellow -NoNewline
            Write-Host '| ' -ForegroundColor DarkGray -NoNewline
            Write-Host 'Gen-TSA.crt not SHA256' -ForegroundColor Red

            $PrintTSAGlobal = [PSCustomObject]@{}

            Return
        }


        if ( -not ( 'Org.BouncyCastle.X509.Store.IX509Store' -as [type] ))
        {
            Add-Type -Path $BouncyDll -ErrorAction Stop
        }

        if ( -not ( 'TimeStamp.TSResponder' -as [type] ))
        {
            $cp = [System.CodeDom.Compiler.CompilerParameters]::new(@('System.dll','System.Core.dll',$BouncyDll))
            $cp.TempFiles = [System.CodeDom.Compiler.TempFileCollection]::new($ScratchDirGlobal,$false)
            $cp.GenerateInMemory = $true
            $cp.CompilerOptions = '/platform:anycpu /nologo'

            Add-Type -TypeDefinition $TimeStampServer -ErrorAction Stop -Language CSharp -CompilerParameters $cp
        }



        [string] $Alg1 = $SigAlg1.ToUpper()
        [string] $Alg2 = $SigAlg2.ToUpper()

        [bool] $admin   = $false
        [bool] $Online1 = $false
        [bool] $Online2 = $false

        if ( ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
        {
            $admin = $true

            if ( $BoolStartLocalTsGlobal )
            {
                # Если хоть один не подходит или не стартовал сервер, запустить/перезапустить оба
                if ( -not (( $PrintTSAGlobal.Started ) -and ( $PrintTSAGlobal.print1 -eq $print1 ) -and ( $PrintTSAGlobal.print2 -eq $print2 )))
                {
                    [TimeStamp.Program]::StopListener()
                    [TimeStamp.Program]::StartResponder($Tsa1Crt, $TsaKey, $Alg1, $true)
                    [TimeStamp.Program]::StartResponder($Tsa2Crt, $TsaKey, $Alg2, $true)
                }

                $Online1 = Check-Local-Server -Url "http://localhost/TS-$Alg1"
                $Online2 = Check-Local-Server -Url "http://localhost/TS-$Alg2"
            }
            else
            {
                [TimeStamp.Program]::StopListener()
            }
        }

        if ( $Online1 -and $Online2 )
        {
            Write-Host '  TSA1 server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '● ' -ForegroundColor Green -NoNewline
            Write-Host '| ' -ForegroundColor DarkGray -NoNewline
            Write-Host "http://localhost/TS-$Alg1   " -ForegroundColor Blue -NoNewline
            Write-Host '/ ' -ForegroundColor DarkGray -NoNewline
            Write-Host "http://localhost/TS-$Alg1/yyyy-MM-ddTHH:mm:ss" -ForegroundColor Blue -NoNewline

            if ( $BoolUseBuiltInTsaGlobal )
            {
                Write-Host '   | ' -ForegroundColor DarkGray -NoNewline
                Write-Host 'Use Built-In TSA' -ForegroundColor Blue
            }
            else
            {
                Write-Host '   | Use Local server' -ForegroundColor DarkGray
            }

            Write-Host '  TSA2 server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '● ' -ForegroundColor Green -NoNewline
            Write-Host '| ' -ForegroundColor DarkGray -NoNewline
            Write-Host "http://localhost/TS-$Alg2 " -ForegroundColor Blue -NoNewline
            Write-Host '/ ' -ForegroundColor DarkGray -NoNewline
            Write-Host "http://localhost/TS-$Alg2/yyyy-MM-ddTHH:mm:ss" -ForegroundColor Blue -NoNewline

            if ( $BoolUseBuiltInTsaGlobal )
            {
                Write-Host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-Host 'Use Built-In TSA' -ForegroundColor Blue
            }
            else
            {
                Write-Host ' | Use Local server' -ForegroundColor DarkGray
            }

            # Сохранение Hash подключенного сертификата
            $PrintTSAGlobal = [PSCustomObject]@{ print1 = $print1 ; print2 = $print2 ; Alg1 = $Alg1 ; Alg2 = $Alg2 ; Started = $true }

            Return
        }
        else
        {
            Write-Host '   TSA server: ' -ForegroundColor DarkGray -NoNewline
            Write-Host '○ ' -ForegroundColor DarkYellow -NoNewline
            Write-Host '| ' -ForegroundColor DarkGray -NoNewline
 
            if ( $BoolUseBuiltInTsaGlobal )
            {
                Write-Host '[Not active]' -ForegroundColor DarkGray -NoNewline
                Write-Host '      | ' -ForegroundColor DarkGray -NoNewline
                Write-Host 'Use Built-In TSA' -ForegroundColor Blue

                # Сохранение Hash используемого сертификата
                $PrintTSAGlobal = [PSCustomObject]@{ print1 = $print1 ; print2 = $print2 ; Alg1 = $Alg1 ; Alg2 = $Alg2 ; Started = $false }
            }
            else
            {
                Write-Host '[Not active]' -ForegroundColor Yellow -NoNewline

                if ( -not $admin )
                {
                    Write-Host ' [not admin] ' -ForegroundColor Yellow -NoNewline
                    Write-Host '|' -ForegroundColor DarkGray -NoNewline
                    Write-Host ' Use Local server' -ForegroundColor Red
                }
                else
                {
                    Write-Host '      | ' -ForegroundColor DarkGray -NoNewline
                    Write-Host 'Use Local server' -ForegroundColor Red
                }

                $PrintTSAGlobal = [PSCustomObject]@{}
            }

            Return
        }
    }
    else
    {
        Write-Host '   TSA server: ' -ForegroundColor DarkGray -NoNewline
        Write-Host '○ ' -ForegroundColor DarkYellow -NoNewline
        Write-Host '| No Gen-TSA1.crt/Gen-TSA2.crt/Gen-TSA.key' -ForegroundColor DarkGray

        $PrintTSAGlobal = [PSCustomObject]@{}

        Return
    }
}

